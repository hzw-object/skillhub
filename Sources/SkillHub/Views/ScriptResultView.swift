import SwiftUI

struct ScriptResultView: View {
    let result: ScriptResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("退出码：\(result.exitCode)\(result.timedOut ? "（超时）" : "")\(result.truncated ? "（输出已截断）" : "")")
                .font(.caption).foregroundStyle(.secondary)
            if !result.stdout.isEmpty {
                Text("stdout").font(.caption).bold()
                ScrollView { Text(result.stdout).font(.caption).monospaced().frame(maxWidth: .infinity, alignment: .leading) }
                    .frame(height: 120).background(.quaternary)
            }
            if !result.stderr.isEmpty {
                Text("stderr").font(.caption).bold()
                ScrollView { Text(result.stderr).font(.caption).monospaced().frame(maxWidth: .infinity, alignment: .leading) }
                    .frame(height: 80).background(.quaternary)
            }
        }
    }
}
