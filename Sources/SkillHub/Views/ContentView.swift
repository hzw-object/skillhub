import SwiftUI

struct ContentView: View {
    @State private var model = AppModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(model: model)
        } content: {
            SkillListView(model: model)
        } detail: {
            if let id = model.selectedEntryID,
               let entry = model.entries.first(where: { $0.id == id }) {
                SkillDetailView(entry: entry, model: model)
            } else {
                ContentUnavailableView("选择一个 skill", systemImage: "square.stack.3d.up",
                                       description: Text("从列表中选一个 skill 查看详情"))
            }
        }
        .task {
            if model.entries.isEmpty { await model.scan() }
        }
    }
}
