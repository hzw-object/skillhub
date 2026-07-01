import Foundation

struct SkillGroup: Identifiable {
    let source: SkillSource
    let entries: [SkillEntry]
    var id: String { source.rawValue }
}
