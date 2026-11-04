import Foundation
import SimulatorsKit

/// A table of runtimes Apple offers for download. Numbered when the user picks from it, otherwise
/// followed by a count; with an Installed column when the installed runtimes are given.
struct AvailableRuntimeTable {
    let runtimes: [AvailableRuntime]
    var installed: [InstalledRuntime]?
    var numbered = false
    var locale: Locale = .current

    func render() -> String {
        var header = ["Runtime", "Build", "Arch", "Size"]
        if installed != nil { header.append("Installed") }

        let rows = runtimes.map { runtime in
            var row = [
                runtime.name,
                runtime.build,
                runtime.downloads.map(\.variant.rawValue).joined(separator: ", "),
                runtime.defaultDownload.sizeBytes.fileSize(locale: locale),
            ]
            if let installed { row.append(runtime.isInstalled(in: installed) ? "yes" : "") }
            return row
        }
        guard !numbered else {
            return TextTable(header: ["#"] + header, rows: rows.enumerated().map { ["\($0.offset + 1)"] + $0.element })
                .render()
        }
        let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
        return TextTable(header: header, rows: rows).render() + "\n\n" + count
    }
}
