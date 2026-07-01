import Foundation

final class ScriptRunner {
    static let maxOutput = 10_000

    static func run(script: ScriptFile) -> ScriptResult {
        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()
        if let interp = script.language.interpreter {
            // 解释器路径作为可执行文件，脚本路径作为独立参数（不经过 shell，避免注入）。
            // 对于 "/usr/bin/env <tool>" 形式的解释器，拆出首个 token 作为可执行文件，
            // 其余作为解释器自身参数，再追加脚本路径。
            let parts = interp.split(separator: " ").map(String.init)
            let interpPath = parts.first ?? interp
            let interpArgs = Array(parts.dropFirst()) + [script.id]
            process.executableURL = URL(fileURLWithPath: interpPath)
            process.arguments = interpArgs
        } else {
            // 直接执行（脚本自带 +x）
            process.executableURL = URL(fileURLWithPath: script.id)
            process.arguments = []
        }
        process.standardOutput = outPipe
        process.standardError = errPipe

        let outData = NSMutableData()
        let errData = NSMutableData()
        let outHandle = outPipe.fileHandleForReading
        let errHandle = errPipe.fileHandleForReading
        outHandle.readabilityHandler = { outData.append($0.availableData) }
        errHandle.readabilityHandler = { errData.append($0.availableData) }

        do {
            try process.run()
        } catch {
            return ScriptResult(stdout: "", stderr: error.localizedDescription,
                                 exitCode: -1, timedOut: false, truncated: false)
        }

        let deadline = Date().addingTimeInterval(30)
        var timedOut = false
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }
        if process.isRunning {
            process.terminate()
            timedOut = true
        }
        process.waitUntilExit()
        outHandle.readabilityHandler = nil
        errHandle.readabilityHandler = nil

        let (outStr, outTrunc) = truncate(String(data: outData as Data, encoding: .utf8) ?? "")
        let (errStr, errTrunc) = truncate(String(data: errData as Data, encoding: .utf8) ?? "")
        return ScriptResult(stdout: outStr, stderr: errStr,
                            exitCode: Int(process.terminationStatus),
                            timedOut: timedOut, truncated: outTrunc || errTrunc)
    }

    private static func truncate(_ s: String) -> (String, Bool) {
        if s.count <= maxOutput { return (s, false) }
        let end = s.index(s.startIndex, offsetBy: maxOutput)
        return (String(s[s.startIndex..<end]), true)
    }
}
