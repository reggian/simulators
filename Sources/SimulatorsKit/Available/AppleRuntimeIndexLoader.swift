import Foundation

/// Downloads the runtime index Xcode itself uses.
public struct AppleRuntimeIndexLoader: RuntimeIndexLoader {
    static let url = URL(string: "https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex")!

    public init() {}

    public func loadIndex() async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: Self.url)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw RuntimeIndexUnavailable(statusCode: status) }
        return data
    }
}
