import Foundation

enum ScriptLanguage: String, CaseIterable {
    case shell, python, node, other

    static func from(pathExtension: String) -> ScriptLanguage {
        switch pathExtension.lowercased() {
        case "sh", "bash":  return .shell
        case "py":          return .python
        case "js":          return .node
        default:           return .other
        }
    }

    var interpreter: String? {
        switch self {
        case .shell:  return "/bin/bash"
        case .python: return "/usr/bin/env python3"
        case .node:   return "/usr/bin/env node"
        case .other:  return nil
        }
    }
}

struct ScriptFile: Identifiable, Hashable {
    let id: String             // 绝对路径
    let name: String           // 文件名
    let relativePath: String  // 相对 skill 目录
    let sizeBytes: Int
    let language: ScriptLanguage
    let contentPreview: String  // 前 50 行

    static func make(at absolutePath: String, skillDirPath: String) throws -> ScriptFile {
        let url = URL(fileURLWithPath: absolutePath)
        let name = url.lastPathComponent
        let attrs = (try? FileManager.default.attributesOfItem(atPath: absolutePath)) ?? [:]
        let sizeBytes = (attrs[.size] as? Int) ?? 0
        let language = ScriptLanguage.from(pathExtension: url.pathExtension)
        let relativePath: String = {
            let skillDir = URL(fileURLWithPath: skillDirPath)
            return url.path.replacingOccurrences(of: skillDir.path + "/", with: "")
        }()
        let contentPreview = ScriptFile.readFirst50Lines(at: absolutePath)
        return ScriptFile(id: absolutePath, name: name, relativePath: relativePath,
                          sizeBytes: sizeBytes, language: language,
                          contentPreview: contentPreview)
    }

    private static func readFirst50Lines(at path: String) -> String {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let text = String(data: data, encoding: .utf8) else { return "" }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.prefix(50).joined(separator: "\n")
    }
}
