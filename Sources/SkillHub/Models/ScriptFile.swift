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
    /// 完整文件内容。用于详情页的目录树预览（替代早期只读前 50 行），
    /// 也作为脚本预览 sheet 的 fallback。
    let content: String
    /// 前 50 行预览，保留给需要截断展示的场景。
    var contentPreview: String { contentPreviewValue }

    private let contentPreviewValue: String

    /// 测试与构造桩用的便捷初始化器：仅给出运行所需字段，`content` 默认空。
    init(id: String, name: String, relativePath: String, sizeBytes: Int,
         language: ScriptLanguage, content: String = "", contentPreview: String? = nil) {
        self.id = id
        self.name = name
        self.relativePath = relativePath
        self.sizeBytes = sizeBytes
        self.language = language
        self.content = content
        self.contentPreviewValue = contentPreview ?? content
    }

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
        let content = ScriptFile.read(at: absolutePath)
        let preview = ScriptFile.first50Lines(of: content)
        return ScriptFile(id: absolutePath, name: name, relativePath: relativePath,
                          sizeBytes: sizeBytes, language: language,
                          content: content, contentPreview: preview)
    }

    private static func read(at path: String) -> String {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }

    private static func first50Lines(of text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.prefix(50).joined(separator: "\n")
    }
}
