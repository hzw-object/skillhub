import SwiftUI
import MarkdownUI

struct SkillDetailView: View {
    let entry: SkillEntry
    @Bindable var model: AppModel
    @State private var scriptToRun: ScriptFile?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MetaInfoCard(entry: entry)
                Divider()
                Text("SKILL.md")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Markdown(MarkdownRenderer.clean(model.loadSkillMd(for: entry)))
                    .markdownTheme(.skill)
                    .markdownCodeSyntaxHighlighter(HighlightrCodeSyntaxHighlighter())
                    .textSelection(.enabled)
                Divider()
                Text("文件")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                FileTreeView(skillDirPath: entry.skillDirPath) { sf in
                    scriptToRun = sf
                }
            }
            .padding(24)
            .frame(maxWidth: 720, alignment: .leading)
        }
        .navigationTitle(entry.name)
        .sheet(item: $scriptToRun) { sf in
            ScriptPreviewSheet(script: sf)
        }
    }
}
