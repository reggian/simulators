/// One architecture variant of a downloadable runtime.
public struct RuntimeDownload: Equatable, Sendable {
    public let variant: ArchitectureVariant
    public let sizeBytes: Int64

    public init(variant: ArchitectureVariant, sizeBytes: Int64) {
        self.variant = variant
        self.sizeBytes = sizeBytes
    }
}
