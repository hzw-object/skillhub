import SwiftUI

struct SkillListView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("搜索 skill…", text: $model.query)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.bar)
            Divider()
            List(selection: $model.selectedEntryID) {
                ForEach(model.filteredAndGrouped) { group in
                    Section(group.source.displayName) {
                        ForEach(group.entries) { entry in
                            // 一个 name 在该 source 下若有多个版本，归为一个「版本组」。
                            let others = model.filteredVersions(forName: entry.name)
                                .filter { $0.source == entry.source }
                            let isHead = others.first?.id == entry.id
                            let expanded = model.expandedKeys
                                .contains(SkillGroupKey(source: entry.source, name: entry.name))
                            let shown = others.count > 1 && expanded
                            // 折叠时仅展示最高版本这一行；展开时展示全部版本行。
                            if shown || others.count <= 1 || isHead {
                                SkillRowView(entry: entry, isSelected: entry.id == model.selectedEntryID)
                                    .tag(entry.id)
                            }
                            // 版本切换按钮统一挂在组的首行，确保始终可见。
                            if others.count > 1 && isHead {
                                versionToggle(source: entry.source, name: entry.name, others: others, expanded: expanded)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Skills")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await model.refresh() }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    /// 版本切换按钮：展开/收起共用一个，状态由 `expandedKeys` 驱动，
    /// 避免旧实现里按钮随首行一同被折叠隐藏而失效。
    @ViewBuilder
    private func versionToggle(source: SkillSource, name: String, others: [SkillEntry], expanded: Bool) -> some View {
        let key = SkillGroupKey(source: source, name: name)
        Button {
            if expanded {
                model.expandedKeys.remove(key)
            } else {
                model.expandedKeys.insert(key)
            }
        } label: {
            HStack(spacing: 2) {
                Image(systemName: expanded ? "chevron.down" : "chevron.right")
                    .font(.caption2)
                Text(expanded ? "收起 \(others.count - 1) 个版本" : "还有 \(others.count - 1) 个版本")
            }
        }
        .buttonStyle(.borderless)
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.leading, 4)
    }
}
