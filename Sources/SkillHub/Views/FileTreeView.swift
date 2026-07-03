import SwiftUI

/// 文件树节点：既能表示目录，也能表示文件。用 `FileNode` 作为 `OutlineGroup` 的元素，
/// 由它自己的 `children` 递归构成可折叠的目录树（保留 scripts/ 这类层级），
/// 而不像旧实现那样把所有文件拍平成一个列表。
struct FileNode: Identifiable, Hashable {
    let id: String               // 绝对路径，天然唯一
    let name: String             // 显示名（文件/目录名）
    let relativePath: String     // 相对 skill 目录
    let isDirectory: Bool
    var children: [FileNode]?    // 目录才有；文件为 nil
    let script: ScriptFile?      // 文件才有；目录为 nil
    var isExpanded: Bool = false
}

struct FileTreeView: View {
    let skillDirPath: String
    let onRunScript: (ScriptFile) -> Void

    @State private var roots: [FileNode] = []
    @State private var selected: FileNode?
    @State private var preview: ScriptFile?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("文件").font(.headline)
            OutlineGroup(roots, id: \.id, children: \.children) { node in
                row(for: node)
            }
            if let pv = preview {
                contentPanel(for: pv)
            } else if let sel = selected {
                Text(sel.relativePath)
                    .font(.caption).monospaced().foregroundStyle(.secondary)
            }
        }
        .task { load() }
    }

    /// 单行：目录显示文件夹图标，文件按扩展名显示对应图标，
    /// 脚本类（sh/py/js/cjs/mjs）多一个「运行」按钮。
    @ViewBuilder
    private func row(for node: FileNode) -> some View {
        HStack(spacing: 4) {
            Image(systemName: node.isDirectory
                ? (node.isExpanded ? "folder.open" : "folder")
                : iconFor(node.script))
            Text(node.name).monospaced().lineLimit(1)
            Spacer(minLength: 0)
            if let script = node.script, script.language.interpreter != nil {
                Button("运行") { onRunScript(script) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { select(node) }
    }

    /// 选中文件：展开完整内容预览，并把它送到 sheet 以便运行。
    private func select(_ node: FileNode) {
        guard !node.isDirectory else { return }
        selected = node
        preview = node.script
    }

    /// 完整内容面板：替代旧版「只读 50 行」的预览，能看到整份文件。
    private func contentPanel(for sf: ScriptFile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(sf.relativePath).font(.caption).monospaced().foregroundStyle(.secondary)
                    Text("· \(sf.sizeBytes) 字节 · \(sf.language.rawValue)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text(sf.content)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(8)
        }
        .frame(height: 220)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }

    private func iconFor(_ sf: ScriptFile?) -> String {
        guard let sf else { return "doc" }
        switch sf.language {
        case .shell:  return "terminal"
        case .python: return "chevron.left.forwardslash.chevron.right"
        case .node:   return "curlybraces"
        case .other:  return "doc.text"
        }
    }

    // MARK: - 载入

    /// 按目录结构递归构造 `FileNode` 树，保持相对路径层级。
    /// `ScriptFile` 现在携带完整 `content`（不只前 50 行），目录节点置 `script=nil`。
    private func load() {
        let url = URL(fileURLWithPath: skillDirPath)
        roots = buildChildren(at: url, relativeRoot: skillDirPath).sorted()
    }

    private func buildChildren(at dir: URL, relativeRoot: String) -> [FileNode] {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: dir.path) else { return [] }
        var nodes: [FileNode] = []
        for name in names {
            let full = dir.appendingPathComponent(name)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: full.path, isDirectory: &isDir) else { continue }
            let rel = (full.path as NSString).replacingOccurrences(of: relativeRoot + "/", with: "")
            if isDir.boolValue {
                let kids = buildChildren(at: full, relativeRoot: relativeRoot).sorted()
                nodes.append(FileNode(id: full.path, name: name, relativePath: rel,
                                      isDirectory: true, children: kids, script: nil))
            } else {
                let script = try? ScriptFile.make(at: full.path, skillDirPath: skillDirPath)
                nodes.append(FileNode(id: full.path, name: name, relativePath: rel,
                                      isDirectory: false, children: nil, script: script))
            }
        }
        return nodes
    }
}

extension FileNode: Comparable {
    static func < (lhs: FileNode, rhs: FileNode) -> Bool {
        // 目录排前，同级按名字升序，让 SKILL.md 这类关键文件靠上。
        if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
        return lhs.name < rhs.name
    }
}
