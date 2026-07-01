import Foundation

struct SkillEntry: Identifiable, Hashable {
    let id: String            // 绝对路径，天然唯一且区分多版本
    let name: String          // front matter 的 name，无则用目录名
    let description: String  // front matter 的 description
    let source: SkillSource
    let skillDirPath: String  // skill 目录绝对路径
    let skillMdPath: String  // SKILL.md 绝对路径
    let version: String?      // 路径中的版本号（如 "6.1.0"），无则 nil
    let sizeBytes: Int        // skill 目录总大小
    let fileCount: Int        // skill 目录下文件总数
}
