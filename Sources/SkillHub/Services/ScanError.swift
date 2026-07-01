import Foundation

/// 单个扫描根目录失败的结构化错误。
/// 用于在侧边栏展示对应来源的红色告警（spec §7.1）。
struct ScanError: Hashable {
    let source: SkillSource
    let path: String
    let message: String
}
