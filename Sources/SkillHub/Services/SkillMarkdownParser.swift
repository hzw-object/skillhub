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
                    if kv.value.isEmpty && line.contains("|") {
                        // 块标量：后续缩进行直到 ---
                        var block: [String] = []
                        var j = i + 1
                        while j < lines.count && lines[j].trimmingCharacters(in: .whitespaces) != "---"
                              && (lines[j].hasPrefix(" ") || lines[j].hasPrefix("\t")) {
                            block.append(lines[j].trimmingCharacters(in: .whitespaces))
                            j += 1
                        }
                        description = block.joined(separator: "\n")
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

    private static func parseLine(_ line: String) -> (key: String, value: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let colonIdx = trimmed.firstIndex(of: ":") else { return nil }
        let key = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
        var value = String(trimmed[trimmed.index(after: colonIdx)...])
            .trimmingCharacters(in: .whitespaces)
        // 去引号
        if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
            value = String(value.dropFirst().dropLast())
        }
        // 去掉块标量标记 `|`
        if value == "|" { value = "" }
        return (key, value)
    }
}
