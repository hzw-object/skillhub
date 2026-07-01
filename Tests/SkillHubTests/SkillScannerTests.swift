import Testing
import Foundation
@testable import SkillHub

@Suite("SkillScannerTests") struct SkillScannerTests {
    @Test func testScanStandardRoot() throws {
        let fixtures = fixturesRoot()
        let root = SkillRoot(path: fixtures, source: .personal)
        let entries = SkillScanner.scanRoot(root)
        #expect(entries.contains { $0.name == "standard-skill" })
        #expect(entries.contains { $0.name == "multi" })
        #expect(entries.contains { $0.name == "scripted" })
    }

    @Test func testNoFrontMatterUsesDirName() throws {
        let fixtures = fixturesRoot()
        let root = SkillRoot(path: fixtures, source: .personal)
        let entries = SkillScanner.scanRoot(root)
        let noFm = entries.first { $0.skillDirPath.contains("no-frontmatter") }
        #expect(noFm != nil)
        #expect(noFm?.name == "no-frontmatter")
    }

    @Test func testBrokenYamlDoesNotCrash() throws {
        let fixtures = fixturesRoot()
        let root = SkillRoot(path: fixtures, source: .personal)
        _ = SkillScanner.scanRoot(root) // 不崩溃即通过
    }

    @Test func testSizeAndFileCount() throws {
        let fixtures = fixturesRoot()
        let root = SkillRoot(path: fixtures, source: .personal)
        let entries = SkillScanner.scanRoot(root)
        let scripted = entries.first { $0.name == "scripted" }
        #expect(scripted != nil)
        #expect(scripted?.fileCount ?? 0 > 1) // SKILL.md + 3 scripts
        #expect(scripted?.sizeBytes ?? 0 > 0)
    }

    private func fixturesRoot() -> String {
        // Bundle.module 由 .copy("Fixtures") 注入。
        // 注意：原 brief 使用 Bundle(for: type(of: self))，但本测试是 struct，
        // type(of: self) 得到 struct 元类型，Bundle(for:) 仅接受 Class 元类型，无法编译。
        // 改用 Bundle.module（SwiftPM 为带 resources 的 target 生成的固定 bundle）。
        let url = Bundle.module.resourceURL?
            .appendingPathComponent("Fixtures")
        return url?.path ?? ""
    }
}
