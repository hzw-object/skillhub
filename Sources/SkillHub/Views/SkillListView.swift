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
                            SkillRowView(entry: entry, isSelected: entry.id == model.selectedEntryID)
                                .tag(entry.id)
                            if !model.expandedNames.contains(entry.name) {
                                let others = model.filteredVersions(forName: entry.name)
                                if others.count > 1 {
                                    Button("还有 \(others.count - 1) 个版本") {
                                        model.expandedNames.insert(entry.name)
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
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
}
