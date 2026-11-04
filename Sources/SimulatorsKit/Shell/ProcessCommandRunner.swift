import Foundation

/// Runs commands with `Process`.
public struct ProcessCommandRunner: CommandRunner {
    public init() {}

    public func run(_ executable: String, _ arguments: [String]) async throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let output = Pipe()
        let errorOutput = Pipe()
        process.standardOutput = output
        process.standardError = errorOutput

        try process.run()

        // Drain both pipes concurrently, so a full stderr buffer can't block the process.
        async let outputData = Self.readToEnd(output.fileHandleForReading)
        async let errorData = Self.readToEnd(errorOutput.fileHandleForReading)
        let (standardOutput, standardError) = try await (outputData, errorData)

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw CommandFailure(
                command: [executable] + arguments,
                exitCode: process.terminationStatus,
                standardError: String(decoding: standardError, as: UTF8.self)
            )
        }
        return standardOutput
    }

    public func runAttached(_ executable: String, _ arguments: [String]) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        // Without pipes, the process inherits this one's standard input, output and error.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            process.terminationHandler = { _ in continuation.resume() }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        guard process.terminationStatus == 0 else {
            throw CommandFailure(command: [executable] + arguments, exitCode: process.terminationStatus, standardError: "")
        }
    }

    private static func readToEnd(_ handle: FileHandle) async throws -> Data {
        var data = Data()
        for try await byte in handle.bytes {
            data.append(byte)
        }
        return data
    }
}
