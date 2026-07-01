import SwiftUI

struct SidebarView: View {
    @Bindable var model: AppModel

    var body: some View {
        List(selection: Binding(
            get: { model.selectedSources.first ?? .personal },
            set: { src in model.selectedSources = [src] }
        )) {
            Section {
                Label("全部", systemImage: "square.grid.2x2")
                    .tag(SkillSource.personal) // 占位 tag；"全部"由工具栏按钮处理
                    .onTapGesture { model.selectedSources = [] }
            }
            Section("来源") {
                ForEach(SkillSource.allCases) { src in
                    HStack {
                        Label(src.displayName, systemImage: src.icon)
                        Spacer()
                        Text("\(count(for: src))")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .tag(src)
                    .onTapGesture { model.selectedSources = [src] }
                }
            }
        }
        .navigationTitle("SkillHub")
    }

    private func count(for source: SkillSource) -> Int {
        model.entries.filter { $0.source == source }.count
    }
}
