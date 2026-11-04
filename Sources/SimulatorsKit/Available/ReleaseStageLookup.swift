/// Release stages of runtimes by platform and build, from Apple's index. Installed runtimes don't
/// record whether they're a beta; only the index does.
public struct ReleaseStageLookup: Sendable {
    private let stages: [Key: ReleaseStage]

    /// A lookup that knows no stages, for when the index isn't available.
    public static let empty = ReleaseStageLookup(available: [])

    public init(available: [AvailableRuntime]) {
        stages = Dictionary(available.map { (Key(platform: $0.platform, build: $0.build), $0.stage) }) { first, _ in first }
    }

    /// The stage of `runtime`, or `nil` when the index doesn't list its build.
    public func stage(of runtime: InstalledRuntime) -> ReleaseStage? {
        stages[Key(platform: runtime.platform, build: runtime.build)]
    }

    /// Loads the index, giving up after `timeout` or on any error: the stages only label runtimes,
    /// so they must never hold up or break a command.
    public static func load(from service: AvailableRuntimeService, timeout: Duration) async -> ReleaseStageLookup {
        await withTaskGroup(of: ReleaseStageLookup?.self) { group in
            group.addTask { try? await ReleaseStageLookup(available: service.availableRuntimes()) }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first ?? .empty
        }
    }

    private struct Key: Hashable {
        let platform: SimulatorPlatform
        let build: String
    }
}
