import Foundation

final class SkillScanner {
    func scan() async -> [SkillEntry] {
        let roots = PathProvider.rootDirectories()
        return await withTaskGroup(of: [SkillEntry].self) { group in
            for root in roots {
                group.addTask { SkillScanner.scanRoot(root) }
            }
            var all: [SkillEntry] = []
            for await batch in group {
                all.append(contentsOf: batch)
            }
            return all.sorted { lhs, rhs in
                if lhs.source.rawValue != rhs.source.rawValue {
                    return lhs.source.rawValue < rhs.source.rawValue
                }
                if lhs.name != rhs.name { return lhs.name < rhs.name }
                return (lhs.version ?? "") > (rhs.version ?? "")
            }
        }
    }

    static func scanRoot(_ root: SkillRoot) -> [SkillEntry] {
        let fm = FileManager.default
        guard let subdirs = try? fm.contentsOfDirectory(atPath: root.path) else { return [] }
        var entries: [SkillEntry] = []
        var isDir: ObjCBool = false
        for sub in subdirs {
            let dir = root.path + "/" + sub
            guard fm.fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue else { continue }
            let md = dir + "/SKILL.md"
            guard fm.fileExists(atPath: md) else { continue }
            let content = (try? String(contentsOfFile: md, encoding: .utf8)) ?? ""
            let fm_ = SkillMarkdownParser.parse(content)
            let name = fm_.name.isEmpty ? sub : fm_.name
            let (size, count) = directoryStats(at: dir)
            entries.append(SkillEntry(
                id: dir, name: name, description: fm_.description,
                source: root.source, skillDirPath: dir, skillMdPath: md,
                version: versionFrom(path: root.path),
                sizeBytes: size, fileCount: count
            ))
        }
        return entries
    }

    private static func directoryStats(at path: String) -> (Int, Int) {
        var size = 0
        var count = 0
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: path) else { return (0, 0) }
        while let item = enumerator.nextObject() as? String {
            let full = path + "/" + item
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: full, isDirectory: &isDir), !isDir.boolValue {
                count += 1
                if let s = (try? fm.attributesOfItem(atPath: full)[.size]) as? Int {
                    size += s
                }
            }
        }
        return (size, count)
    }

    private static func versionFrom(path: String) -> String? {
        // 路径形如 .../<marketplace>/<plugin>/<version>/skills
        let comps = path.split(separator: "/").map(String.init)
        guard let vIdx = comps.lastIndex(of: "skills").flatMap({ $0 - 1 }) else { return nil }
        let v = comps[vIdx]
        let pattern = #"^\d+\.\d+\.\d+$"#
        return v.range(of: pattern, options: .regularExpression) != nil ? v : nil
    }
}
