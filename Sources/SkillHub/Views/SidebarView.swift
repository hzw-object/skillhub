import SwiftUI

/// 侧边栏选区：`all` 表示「全部」（清空来源过滤），`source(SkillSource)` 表示选中具体来源。
enum SidebarSelection: Hashable {
    case all
    case source(SkillSource)
}

struct SidebarView: View {
    @Bindable var model: AppModel

    /// 绑定到 `List(selection:)` 的单一选区。`nil`/`all` 表示「全部」。
    private var selection: Binding<SidebarSelection> {
        Binding(
            get: {
                if let src = model.selectedSources.first, model.selectedSources.count == 1 {
                    return .source(src)
                }
                return .all
            },
            set: { value in
                switch value {
                case .all:
                    model.selectedSources = []
                case .source(let src):
                    model.selectedSources = [src]
                }
            }
        )
    }

    var body: some View {
        List(selection: selection) {
            Section {
                Label("全部", systemImage: "square.grid.2x2")
                    .tag(SidebarSelection.all)
            }
            Section("来源") {
                ForEach(SkillSource.allCases) { src in
                    HStack {
                        Label(src.displayName, systemImage: src.icon)
                        if model.scanErrors.contains(where: { $0.source == src }) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                        Spacer()
                        Text("\(count(for: src))")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .tag(SidebarSelection.source(src))
                }
            }
        }
        .navigationTitle("SkillHub")
    }

    private func count(for source: SkillSource) -> Int {
        model.entries.filter { $0.source == source }.count
    }
}
