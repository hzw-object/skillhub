import SwiftUI

struct SkillDetailView: View {
    let entry: SkillEntry
    @Bindable var model: AppModel
    @State private var scriptToRun: ScriptFile?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MetaInfoCard(entry: entry)
                Text("SKILL.md").font(.headline)
                Text(MarkdownRenderer.render(model.loadSkillMd(for: entry)))
                    .textSelection(.enabled)
                FileTreeView(skillDirPath: entry.skillDirPath) { sf in
                    scriptToRun = sf
                }
            }
            .padding()
        }
        .navigationTitle(entry.name)
        .sheet(item: $scriptToRun) { sf in
            ScriptPreviewSheet(script: sf)
        }
    }
}
