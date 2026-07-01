import SwiftUI
import AppKit

struct MetaInfoCard: View {
    let entry: SkillEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.name).font(.title2).bold()
            if !entry.description.isEmpty {
                Text(entry.description).foregroundStyle(.secondary)
            }
            Divider()
            LabeledContent("来源", value: entry.source.displayName)
            LabeledContent("版本", value: entry.version ?? "—")
            LabeledContent("大小", value: formatBytes(entry.sizeBytes))
            LabeledContent("文件数", value: "\(entry.fileCount)")
            LabeledContent("路径", value: entry.skillDirPath)
                .font(.caption).monospaced()
            HStack {
                Button("在 Finder 中显示") {
                    NSWorkspace.shared.openFile(entry.skillDirPath, withApplication: "Finder")
                }
                Button("复制路径") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(entry.skillDirPath, forType: .string)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func formatBytes(_ b: Int) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var v = Double(b)
        var i = 0
        while v >= 1024, i < units.count - 1 { v /= 1024; i += 1 }
        return String(format: "%.1f %@", v, units[i])
    }
}
