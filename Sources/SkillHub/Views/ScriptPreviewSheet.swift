import SwiftUI

struct ScriptPreviewSheet: View {
    let script: ScriptFile
    @State private var result: ScriptResult?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("预览脚本").font(.headline)
            LabeledContent("路径", value: script.id).font(.caption).monospaced()
            LabeledContent("大小", value: "\(script.sizeBytes) 字节")
            LabeledContent("语言", value: script.language.rawValue)
            Text("预览（前 50 行）").font(.caption).bold()
            ScrollView {
                Text(script.contentPreview).font(.caption).monospaced()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 160).background(.quaternary)

            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Button("执行") {
                    result = ScriptRunner.run(script: script)
                }
                .buttonStyle(.borderedProminent)
            }

            if let r = result {
                Divider()
                ScriptResultView(result: r)
            }
        }
        .padding()
        .frame(width: 560, height: 520)
    }
}
