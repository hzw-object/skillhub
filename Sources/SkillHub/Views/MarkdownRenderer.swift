import Foundation
import SwiftUI

/// Markdown 渲染入口。
///
/// 历史版本用 Foundation 的 `AttributedString(markdown:)` 内联渲染，无法处理标题、列表、
/// 代码块等块级语法，导致 SKILL.md 排版单调。现改由视图层用 `MarkdownUI` 的 `Markdown`
/// 视图做完整块级渲染；本枚举仅保留「清理原始文本 + 提供主题」的职责。
enum MarkdownRenderer {
    /// 渲染前对原始 SKILL.md 做最小清理：
    /// 1. 统一 CRLF → LF；
    /// 2. 剥离首部的 YAML front matter（`---\n...\n---`）——元数据已在 `MetaInfoCard`
    ///    呈现，正文里重复显示原始 YAML 既难看又冗余；
    /// 3. 去掉正文首尾空白行。
    static func clean(_ md: String) -> String {
        let normalized = md.replacingOccurrences(of: "\r\n", with: "\n")
        return stripFrontMatter(normalized)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 仅剥离位于文件**首部**的 front matter。`---` 必须顶格出现在第一行；
    /// 之后的第一个独占一行的 `---`（或 `...`）视为闭合，其后为正文。
    /// 文件中部的 `---`（如分隔线）不受影响。
    static func stripFrontMatter(_ md: String) -> String {
        var lines = md.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let first = lines.first,
              first.trimmingCharacters(in: .whitespaces) == "---" else {
            return md
        }
        // 从第 2 行起找闭合标记（独占一行的 --- 或 ...）
        var closeIndex = -1
        for i in 1..<lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed == "---" || trimmed == "..." {
                closeIndex = i
                break
            }
        }
        guard closeIndex >= 0 else { return md }
        // 闭合标记之后的部分即为正文
        lines.removeFirst(closeIndex + 1)
        return lines.joined(separator: "\n")
    }
}
