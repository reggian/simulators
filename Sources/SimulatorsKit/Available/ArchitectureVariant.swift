/// Which CPU architectures a downloadable runtime contains, as `xcodebuild -architectureVariant`
/// names them.
public enum ArchitectureVariant: String, CaseIterable, Sendable {
    /// Apple silicon only. Smaller; what Xcode downloads by default on an Apple silicon Mac.
    case arm64
    /// Apple silicon and Intel.
    case universal

    /// The variant for an index entry's architectures. Older entries don't list any; they predate
    /// arm64-only runtimes, so they're universal.
    init(architectures: [String]?) {
        let architectures = architectures ?? []
        self = architectures.isEmpty || architectures.contains("x86_64") ? .universal : .arm64
    }
}
