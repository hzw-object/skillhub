import Foundation

enum SkillSource: String, CaseIterable, Identifiable, Hashable {
    case personal
    case superpowers
    case frontendDesign = "frontend_design"
    case ponytail
    case glmPlanUsage = "glm_plan_usage"
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .personal:       return "个人 Skills"
        case .superpowers:    return "Superpowers"
        case .frontendDesign: return "Frontend Design"
        case .ponytail:       return "Ponytail"
        case .glmPlanUsage:   return "GLM Plan Usage"
        case .other:          return "其他"
        }
    }

    var icon: String {
        switch self {
        case .personal:       return "person.crop.square"
        case .superpowers:    return "bolt.square"
        case .frontendDesign: return "paintbrush.square"
        case .ponytail:       return "sparkles.square"
        case .glmPlanUsage:   return "chart.bar.square"
        case .other:          return "questionmark.square"
        }
    }
}
