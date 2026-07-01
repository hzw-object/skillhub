import Testing
import Foundation
@testable import SkillHub

@Suite("ScriptFileTests") struct ScriptFileTests {
    @Test func testLanguageFromExtension() {
        #expect(ScriptLanguage.from(pathExtension: "sh") == .shell)
        #expect(ScriptLanguage.from(pathExtension: "py") == .python)
        #expect(ScriptLanguage.from(pathExtension: "js") == .node)
        #expect(ScriptLanguage.from(pathExtension: "txt") == .other)
        #expect(ScriptLanguage.from(pathExtension: "") == .other)
    }

    @Test func testMakeBuildsFields() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("skill-\(UUID().uuidString)/scripts/hello.sh")
        try FileManager.default.createDirectory(at: temp.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let lines = (0..<60).map { "echo line \($0)" }.joined(separator: "\n")
        try lines.write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp.deletingLastPathComponent().deletingLastPathComponent()) }

        let skillDir = temp.deletingLastPathComponent().deletingLastPathComponent().path
        let f = try ScriptFile.make(at: temp.path, skillDirPath: skillDir)
        #expect(f.name == "hello.sh")
        #expect(f.language == .shell)
        #expect(f.relativePath == "scripts/hello.sh")
        #expect(f.contentPreview.split(separator: "\n").count == 50)
    }
}
