import Foundation

struct ScriptResult {
    let stdout: String
    let stderr: String
    let exitCode: Int
    let timedOut: Bool
    let truncated: Bool
}
