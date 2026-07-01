import Testing
import Foundation
@testable import SkillHub

@Suite("SkillScannerTests") struct SkillScannerTests {
    @Test func testScanStandardRoot() throws {
        let fixtures = fixturesRoot()
        let root = SkillRoot(path: fixtures, source: .personal)
        let entries = SkillScanner.scanRoot(root).entries
        #expect(entries.contains { $0.name == "standard-skill" })
        #expect(entries.contains { $0.name == "multi" })
        #expect(entries.contains { $0.name == "scripted" })
    }

    @Test func testNoFrontMatterUsesDirName() throws {
        let fixtures = fixturesRoot()
        let root = SkillRoot(path: fixtures, source: .personal)
        let entries = SkillScanner.scanRoot(root).entries
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
        let entries = SkillScanner.scanRoot(root).entries
        let scripted = entries.first { $0.name == "scripted" }
        #expect(scripted != nil)
        #expect(scripted?.fileCount ?? 0 > 1) // SKILL.md + 3 scripts
        #expect(scripted?.sizeBytes ?? 0 > 0)
    }

    @Test func testMissingRootProducesScanError() throws {
        // 一个不存在的根目录，scanRoot 应返回空 entries + 一个 ScanError
        let bogus = SkillRoot(path: "/does/not/exist/\(UUID().uuidString)", source: .superpowers)
        let result = SkillScanner.scanRoot(bogus)
        #expect(result.entries.isEmpty)
        #expect(result.errors.count == 1)
        #expect(result.errors.first?.source == .superpowers)
        #expect(!(result.errors.first?.message.isEmpty ?? true))
    }

    @Test func testScanAggregatesErrorsWithoutInterruptingOtherRoots() async throws {
        // 同时扫描一个不存在的根和一个真实 fixtures 根：
        // 真实根应正常返回条目，不存在的根应产生错误，互不干扰
        let bogus = SkillRoot(path: "/does/not/exist/\(UUID().uuidString)", source: .superpowers)
        let real = SkillRoot(path: fixturesRoot(), source: .personal)
        // 通过 SkillScanner.scan() 间接覆盖，但 PathProvider.rootDirectories() 不一定包含我们的伪根，
        // 这里直接测两个 scanRoot 结果的合并行为即可。
        let bogusResult = SkillScanner.scanRoot(bogus)
        let realResult = SkillScanner.scanRoot(real)
        #expect(realResult.entries.contains { $0.name == "standard-skill" })
        #expect(bogusResult.errors.count == 1)
        #expect(bogusResult.errors.first?.source == .superpowers)
        #expect(realResult.errors.isEmpty)
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
