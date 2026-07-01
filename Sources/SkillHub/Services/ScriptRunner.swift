import Foundation

final class ScriptRunner {
    static let maxOutput = 10_000

    static func run(script: ScriptFile) -> ScriptResult {
        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()
        if let interp = script.language.interpreter {
            process.launchPath = "/bin/sh"
            process.arguments = ["-c", "\(interp) \"\(script.id)\""]
        } else {
            process.launchPath = script.id
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
