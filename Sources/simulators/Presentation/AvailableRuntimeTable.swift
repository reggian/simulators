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
            // Installed runtimes are green across the whole row; otherwise betas and RCs are yellow.
            let isInstalled = installed.map(runtime.isInstalled(in:)) ?? false
            let rowStyle: Style? = isInstalled ? .green : nil
            var row = [
                TextTable.Cell(runtime.name, rowStyle ?? (runtime.stage == .release ? nil : .yellow)),
                TextTable.Cell(runtime.build, rowStyle),
                TextTable.Cell(runtime.downloads.map(\.variant.rawValue).joined(separator: ", "), rowStyle),
                TextTable.Cell(runtime.defaultDownload.sizeBytes.fileSize(locale: locale), rowStyle),
            ]
            if installed != nil { row.append(TextTable.Cell(isInstalled ? "yes" : "", rowStyle)) }
            return row
        }
        guard !numbered else {
            return TextTable.numbered(header: header, rows: rows, styler: styler).render()
        }
        let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
        return TextTable(header: header, rows: rows, styler: styler).render() + "\n\n" + styler(count, .dim)
    }
}
