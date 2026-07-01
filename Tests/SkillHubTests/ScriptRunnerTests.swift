import Testing
import Foundation
@testable import SkillHub

@Suite("ScriptRunnerTests") struct ScriptRunnerTests {
    @Test func testEchoSuccess() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("echo-\(UUID().uuidString).sh")
        try "#!/bin/bash\necho hello".write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp) }
        let sf = ScriptFile(id: temp.path, name: temp.lastPathComponent,
                            relativePath: temp.lastPathComponent, sizeBytes: 0,
                            language: .shell, contentPreview: "")
        let r = ScriptRunner.run(script: sf)
        #expect(r.exitCode == 0)
        #expect(r.stdout.contains("hello"))
        #expect(!(r.timedOut))
    }

    @Test func testNonZeroExit() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("exit-\(UUID().uuidString).sh")
        try "#!/bin/bash\nexit 3".write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp) }
        let sf = ScriptFile(id: temp.path, name: temp.lastPathComponent,
                            relativePath: temp.lastPathComponent, sizeBytes: 0,
                            language: .shell, contentPreview: "")
        let r = ScriptRunner.run(script: sf)
        #expect(r.exitCode == 3)
        #expect(!(r.timedOut))
    }

    @Test func testNoPermissionUsesInterpreter() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("noperm-\(UUID().uuidString).sh")
        try "#!/bin/bash\necho works".write(to: temp, atomically: true, encoding: .utf8)
        // 不设置 +x
        defer { try? FileManager.default.removeItem(at: temp) }
        let sf = ScriptFile(id: temp.path, name: temp.lastPathComponent,
                            relativePath: temp.lastPathComponent, sizeBytes: 0,
                            language: .shell, contentPreview: "")
        let r = ScriptRunner.run(script: sf)
        #expect(r.exitCode == 0)
        #expect(r.stdout.contains("works"))
    }

    @Test func testLargeOutputTruncated() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("big-\(UUID().uuidString).sh")
        let body = "#!/bin/bash\n" + (0..<20000).map { "echo line \($0)" }.joined(separator: "\n")
        try body.write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp) }
        let sf = ScriptFile(id: temp.path, name: temp.lastPathComponent,
                            relativePath: temp.lastPathComponent, sizeBytes: 0,
                            language: .shell, contentPreview: "")
        let r = ScriptRunner.run(script: sf)
        #expect(r.truncated)
        #expect(r.stdout.count <= 10000 + 200) // 截断后可能略多于 10000（行尾），留余量
    }
}
