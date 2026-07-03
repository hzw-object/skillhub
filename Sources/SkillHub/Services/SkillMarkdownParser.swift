import Foundation

struct SkillFrontMatter {
    let name: String
    let description: String
}

enum SkillMarkdownParser {
    static func parse(_ md: String) -> SkillFrontMatter {
        var name = ""
        var description = ""

        let lines = md.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return SkillFrontMatter(name: "", description: "")
        }

        var i = 1
        while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces) != "---" {
            let line = lines[i]
            if let kv = parseLine(line) {
                if kv.key == "name" { name = kv.value }
                else if kv.key == "description" {
                    if kv.isBlockScalar {
                        // 块标量：后续缩进行直到 --- 或非缩进行
                        // `|`（字面）保留换行；`>`（折叠）用空格连接成一行。
                        let separator = kv.blockFolded ? " " : "\n"
                        var block: [String] = []
                        var j = i + 1
                        while j < lines.count && lines[j].trimmingCharacters(in: .whitespaces) != "---"
                              && (lines[j].hasPrefix(" ") || lines[j].hasPrefix("\t")) {
                            block.append(lines[j].trimmingCharacters(in: .whitespaces))
                            j += 1
                        }
                        description = block.joined(separator: separator)
                        i = j - 1
                    } else {
                        description = kv.value
                    }
                }
            }
            i += 1
        }
        return SkillFrontMatter(name: name, description: description)
    }

    /// 单行解析结果。
    struct ParsedLine {
        let key: String
        let value: String
        /// 是否为块标量标记（`|` / `>` 及其 `-`/`+` 变体），值为空。
        let isBlockScalar: Bool
        /// 块标量为折叠式（`>`）则为 true，字面式（`|`）为 false。
        let blockFolded: Bool
    }

    private static func parseLine(_ line: String) -> ParsedLine? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let colonIdx = trimmed.firstIndex(of: ":") else { return nil }
        let key = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
        var value = String(trimmed[trimmed.index(after: colonIdx)...])
            .trimmingCharacters(in: .whitespaces)
        // 去引号
        if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
            value = String(value.dropFirst().dropLast())
        }
        // 块标量标记：`|`、`>`，可选后接 `-`（strip）/`+`（keep）chomp 修饰符。
        // 命中后值清空，由调用方消费后续缩进行。
        let blockFolded: Bool
        if value.first == "|" { blockFolded = false }
        else if value.first == ">" { blockFolded = true }
        else { return ParsedLine(key: key, value: value, isBlockScalar: false, blockFolded: false) }
        let marker = value.dropFirst()
        if marker.isEmpty || marker == "-" || marker == "+" {
            return ParsedLine(key: key, value: "", isBlockScalar: true, blockFolded: blockFolded)
        }
        return ParsedLine(key: key, value: value, isBlockScalar: false, blockFolded: false)
    }
}
