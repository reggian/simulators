import Foundation
import SimulatorsKit

/// A table of runtimes Apple offers for download. Numbered when the user picks from it, otherwise
/// followed by a count; with an Installed column when the installed runtimes are given.
struct AvailableRuntimeTable {
    let runtimes: [AvailableRuntime]
    var installed: [InstalledRuntime]?
    var numbered = false
    var styler: Styler = .plain
    var locale: Locale = .current

    func render() -> String {
        var header = ["Runtime", "Build", "Arch", "Size"]
        if installed != nil { header.append("Installed") }

        let rows = runtimes.map { runtime in
            var row = [
                TextTable.Cell(runtime.name),
                TextTable.Cell(runtime.build),
                TextTable.Cell(runtime.downloads.map(\.variant.rawValue).joined(separator: ", ")),
                TextTable.Cell(runtime.defaultDownload.sizeBytes.fileSize(locale: locale)),
            ]
            if let installed { row.append(TextTable.Cell(runtime.isInstalled(in: installed) ? "yes" : "")) }
            return row
        }
        guard !numbered else {
            return TextTable.numbered(header: header, rows: rows, styler: styler).render()
        }
        let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
        return TextTable(header: header, rows: rows, styler: styler).render() + "\n\n" + styler(count, .dim)
    }
}
