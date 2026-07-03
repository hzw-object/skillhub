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
    /// 按 (source, name) 分组：展开/折叠状态以「来源+名称」为键，
    /// 这样跨来源的同名 skill 各自独立展开。
    var expandedKeys: Set<SkillGroupKey> = []
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

    /// 当前过滤后、按 `(source, name)` 分组、同版本去重的条目，
    /// 供 `filteredVersions(forName:)` 计数与展开决策使用。
    var dedupedEntries: [SkillEntry] {
        let byKey: [SkillGroupKey: [SkillEntry]] = Dictionary(
            grouping: filteredEntries,
            by: { SkillGroupKey(source: $0.source, name: $0.name) }
        )
        var out: [SkillEntry] = []
        for versions in byKey.values {
            let sorted = versions.sorted { AppModel.compareVersion($0.version, $1.version) == .orderedDescending }
            // 同一版本号可能出现在多个根目录（ponytail 的 skills/ 与 .openclaw/skills/），
            // 取最高版本一个、丢弃其余重复版本。
            var seen = Set<String>()
            for e in sorted {
                let key = e.version ?? ""
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                out.append(e)
            }
        }
        return out
    }

    var filteredAndGrouped: [SkillGroup] {
        // 先按 (source, name) 分组，再做版本折叠/展开，最后按 source 聚合成 Section。
        let byKey: [SkillGroupKey: [SkillEntry]] = Dictionary(
            grouping: filteredEntries,
            by: { SkillGroupKey(source: $0.source, name: $0.name) }
        )
        var collapsed: [SkillEntry] = []
        for (key, versions) in byKey {
            let sorted = versions.sorted { AppModel.compareVersion($0.version, $1.version) == .orderedDescending }
            // 同一版本号可能出现在多个根目录（ponytail 的 skills/ 与 .openclaw/skills/），
            // 取最高版本一个、丢弃其余重复版本。
            var seen = Set<String>()
            let deduped = sorted.filter { e in
                let k = e.version ?? ""
                guard !seen.contains(k) else { return false }
                seen.insert(k); return true
            }
            if expandedKeys.contains(key) {
                collapsed.append(contentsOf: deduped)
            } else {
                collapsed.append(deduped.first!)
            }
        }
        let grouped = Dictionary(grouping: collapsed, by: \.source)
        return SkillSource.allCases.compactMap { src in
            guard let arr = grouped[src], !arr.isEmpty else { return nil }
            return SkillGroup(source: src, entries: arr.sorted { $0.name < $1.name })
        }
    }

    /// 全量（不受当前过滤影响）的同名同来源条目，按版本降序、去重。
    func versions(forName name: String) -> [SkillEntry] {
        dedupedVersions(of: entries.filter { $0.name == name })
    }

    /// 受当前过滤（source + query）影响的同名同来源条目，按版本降序、去重。
    /// 用于「还有 N 个版本」按钮的计数与展开决策。
    func filteredVersions(forName name: String) -> [SkillEntry] {
        dedupedVersions(of: filteredEntries.filter { $0.name == name })
    }

    private func dedupedVersions(of entries: [SkillEntry]) -> [SkillEntry] {
        let sorted = entries.sorted { AppModel.compareVersion($0.version, $1.version) == .orderedDescending }
        var seen = Set<String>()
        return sorted.filter { e in
            let key = e.version ?? ""
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
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
