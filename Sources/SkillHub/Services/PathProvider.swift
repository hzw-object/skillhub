import Foundation

struct SkillRoot {
    let path: String
    let source: SkillSource
}

enum PathProvider {
    static func rootDirectories() -> [SkillRoot] {
        var roots: [SkillRoot] = []
        let home = NSHomeDirectory()
        let personal = home + "/.claude/skills"
        if FileManager.default.fileExists(atPath: personal) {
            roots.append(SkillRoot(path: personal, source: .personal))
        }

        let cacheBase = home + "/.claude/plugins/cache"
        guard FileManager.default.fileExists(atPath: cacheBase) else { return roots }

        let fm = FileManager.default
        guard let marketplaces = try? fm.contentsOfDirectory(atPath: cacheBase) else { return roots }
        for marketplace in marketplaces {
            let mpPath = cacheBase + "/" + marketplace
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: mpPath, isDirectory: &isDir), isDir.boolValue else { continue }
            guard let plugins = try? fm.contentsOfDirectory(atPath: mpPath) else { continue }
            for plugin in plugins {
                let plPath = mpPath + "/" + plugin
                guard fm.fileExists(atPath: plPath, isDirectory: &isDir), isDir.boolValue else { continue }
                guard let versions = try? fm.contentsOfDirectory(atPath: plPath) else { continue }
                let source = classify(marketplace: marketplace, plugin: plugin)
                for version in versions {
                    let vPath = plPath + "/" + version + "/skills"
                    if fm.fileExists(atPath: vPath, isDirectory: &isDir), isDir.boolValue {
                        roots.append(SkillRoot(path: vPath, source: source))
                    }
                    // ponytail .openclaw/skills 特例
                    let openclaw = plPath + "/" + version + "/.openclaw/skills"
                    if fm.fileExists(atPath: openclaw, isDirectory: &isDir), isDir.boolValue {
                        roots.append(SkillRoot(path: openclaw, source: source))
                    }
                }
            }
        }
        return roots
    }

    static func classify(marketplace: String, plugin: String) -> SkillSource {
        switch (marketplace, plugin) {
        case ("superpowers-marketplace", "superpowers"),
             ("claude-plugins-official", "superpowers"):
            return .superpowers
        case ("claude-plugins-official", "frontend-design"):
            return .frontendDesign
        case ("ponytail", "ponytail"):
            return .ponytail
        case ("zai-coding-plugins", "glm-plan-usage"):
            return .glmPlanUsage
        default:
            return .other
        }
    }
}
