import Foundation

struct SkillGroup: Identifiable {
    let source: SkillSource
    let entries: [SkillEntry]
    var id: String { source.rawValue }
}

/// 「来源 + 名称」组合键：用于把同名但跨来源的 skill 区分为独立分组，
/// 并作为展开/折叠状态的存取键。
struct SkillGroupKey: Hashable {
    let source: SkillSource
    let name: String
}
