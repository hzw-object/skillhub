import Foundation
import Observation

@Observable
final class AppModel {
    var entries: [SkillEntry] = []
    var selectedEntryID: String?
    var query: String = ""
    var selectedSources: Set<SkillSource> = []
    var loading: Bool = false
    var expandedNames: Set<String> = []
    var lastScanDate: Date?
    var scanErrors: [String] = []
    private var skillMdCache: [String: String] = [:]

    var filteredAndGrouped: [SkillGroup] {
        let filtered = entries.filter { e in
            (selectedSources.isEmpty || selectedSources.contains(e.source))
            && matchesQuery(e)
        }
        // 多版本折叠
        var collapsed: [SkillEntry] = []
        let byName: [String: [SkillEntry]] = Dictionary(grouping: filtered, by: \.name)
        for name in byName.keys.sorted() {
            let versions = byName[name]!.sorted { ($0.version ?? "") > ($1.version ?? "") }
            if expandedNames.contains(name) {
                collapsed.append(contentsOf: versions)
            } else {
                collapsed.append(versions.first!)
            }
        }
        // 按 source 分组
        let grouped = Dictionary(grouping: collapsed, by: \.source)
        return SkillSource.allCases.compactMap { src in
            guard let arr = grouped[src], !arr.isEmpty else { return nil }
            return SkillGroup(source: src, entries: arr.sorted { $0.name < $1.name })
        }
    }

    func versions(forName name: String) -> [SkillEntry] {
        entries.filter { $0.name == name }
            .sorted { ($0.version ?? "") > ($1.version ?? "") }
    }

    func scan() async {
        loading = true
        defer { loading = false }
        let scanner = SkillScanner()
        entries = await scanner.scan()
        lastScanDate = Date()
    }

    func refresh() async { await scan() }

    func loadSkillMd(for entry: SkillEntry) -> String {
        if let cached = skillMdCache[entry.id] { return cached }
        let content = (try? String(contentsOfFile: entry.skillMdPath, encoding: .utf8)) ?? ""
        skillMdCache[entry.id] = content
        return content
    }

    private func matchesQuery(_ e: SkillEntry) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        if e.name.lowercased().contains(q) { return true }
        if e.description.lowercased().contains(q) { return true }
        if e.skillDirPath.lowercased().contains(q) { return true }
        return false
    }
}
