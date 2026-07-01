import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var entries: [SkillEntry] = []
    var selectedEntryID: String?
    var query: String = ""
    var selectedSources: Set<SkillSource> = []
    var loading: Bool = false
    var expandedNames: Set<String> = []
    var lastScanDate: Date?
    var scanErrors: [ScanError] = []
    private var skillMdCache: [String: String] = [:]

    /// 当前过滤后的（折叠前）条目集合，复用 `filteredAndGrouped` 的过滤逻辑。
    var filteredEntries: [SkillEntry] {
        entries.filter { e in
            (selectedSources.isEmpty || selectedSources.contains(e.source))
            && matchesQuery(e)
        }
    }

    var filteredAndGrouped: [SkillGroup] {
        // 多版本折叠
        var collapsed: [SkillEntry] = []
        let byName: [String: [SkillEntry]] = Dictionary(grouping: filteredEntries, by: \.name)
        for name in byName.keys.sorted() {
            let versions = byName[name]!.sorted { AppModel.compareVersion($0.version, $1.version) == .orderedDescending }
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

    /// 全量（不受当前过滤影响）的同名条目，按版本降序。
    func versions(forName name: String) -> [SkillEntry] {
        entries.filter { $0.name == name }
            .sorted { AppModel.compareVersion($0.version, $1.version) == .orderedDescending }
    }

    /// 受当前过滤（source + query）影响的同名条目，按版本降序。
    /// 用于「还有 N 个版本」按钮的计数与展开决策。
    func filteredVersions(forName name: String) -> [SkillEntry] {
        filteredEntries.filter { $0.name == name }
            .sorted { AppModel.compareVersion($0.version, $1.version) == .orderedDescending }
    }

    func scan() async {
        loading = true
        defer { loading = false }
        let scanner = SkillScanner()
        let result = await scanner.scan()
        entries = result.entries
        scanErrors = result.errors
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

    /// 语义化版本比较：按 "." 切分，逐段按 Int 比较，缺失段视为 0，
    /// nil 版本视为最低。返回值同 `ComparisonResult`。
    nonisolated static func compareVersion(_ a: String?, _ b: String?) -> ComparisonResult {
        let pa = parseVersion(a)
        let pb = parseVersion(b)
        // 对齐到相同长度，缺失补 0
        let count = max(pa.count, pb.count)
        for i in 0..<count {
            let ai = i < pa.count ? pa[i] : 0
            let bi = i < pb.count ? pb[i] : 0
            if ai < bi { return .orderedAscending }
            if ai > bi { return .orderedDescending }
        }
        return .orderedSame
    }

    nonisolated private static func parseVersion(_ v: String?) -> [Int] {
        guard let v = v else { return [] }
        return v.split(separator: ".").compactMap { Int($0) }
    }
}
