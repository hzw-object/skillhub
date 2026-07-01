import SwiftUI

struct FileTreeView: View {
    let skillDirPath: String
    let onRunScript: (ScriptFile) -> Void
    @State private var files: [ScriptFile] = []
    @State private var previewFile: ScriptFile?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("文件").font(.headline)
            List(files, id: \.id) { f in
                HStack {
                    Image(systemName: iconFor(f))
                    Text(f.relativePath).monospaced()
                    Spacer()
                    if f.language.interpreter != nil {
                        Button("运行") { onRunScript(f) }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { previewFile = f }
            }
            if let pv = previewFile {
                ScrollView {
                    Text(pv.contentPreview)
                        .font(.caption).monospaced()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 160)
                .background(.quaternary)
            }
        }
        .task { loadFiles() }
    }

    private func iconFor(_ f: ScriptFile) -> String {
        switch f.language {
        case .shell:  return "terminal"
        case .python: return "chevron.left.forwardslash.chevron.right"
        case .node:   return "curlybraces"
        case .other:  return "doc"
        }
    }

    private func loadFiles() {
        var collected: [ScriptFile] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: skillDirPath) else { return }
        while let item = enumerator.nextObject() as? String {
            let full = skillDirPath + "/" + item
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: full, isDirectory: &isDir), !isDir.boolValue else { continue }
            if let sf = try? ScriptFile.make(at: full, skillDirPath: skillDirPath) {
                collected.append(sf)
            }
        }
        files = collected.sorted { $0.relativePath < $1.relativePath }
    }
}
