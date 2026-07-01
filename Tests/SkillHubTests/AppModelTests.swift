import Testing
import Foundation
@testable import SkillHub

@MainActor
@Suite("AppModelTests") struct AppModelTests {
    private func entry(_ name: String, _ version: String?, _ source: SkillSource = .personal) -> SkillEntry {
        SkillEntry(id: "/x/\(name)/\(version ?? "0")", name: name, description: "d",
                   source: source, skillDirPath: "/x/\(name)",
                   skillMdPath: "/x/\(name)/SKILL.md", version: version,
                   sizeBytes: 0, fileCount: 0)
    }

    @Test func testSearchByName() {
        let m = AppModel()
        m.entries = [entry("alpha", nil), entry("beta", nil)]
        m.query = "alp"
        #expect(m.filteredAndGrouped.flatMap(\.entries).map(\.name) == ["alpha"])
    }

    @Test func testSourceFilter() {
        let m = AppModel()
        m.entries = [entry("a", nil, .personal), entry("b", nil, .superpowers)]
        m.selectedSources = [.superpowers]
        #expect(m.filteredAndGrouped.flatMap(\.entries).map(\.name) == ["b"])
    }

    @Test func testEmptySourcesMeansAll() {
        let m = AppModel()
        m.entries = [entry("a", nil, .personal), entry("b", nil, .superpowers)]
        #expect(m.filteredAndGrouped.flatMap(\.entries).count == 2)
    }

    @Test func testMultiVersionFoldedByDefault() {
        let m = AppModel()
        m.entries = [entry("brain", "5.1.0"), entry("brain", "6.1.0"), entry("brain", "6.0.3")]
        let names = m.filteredAndGrouped.flatMap(\.entries).map(\.name)
        #expect(names == ["brain"])            // 折叠为一个
        #expect(m.filteredAndGrouped.flatMap(\.entries).first?.version == "6.1.0")
    }

    @Test func testMultiVersionExpanded() {
        let m = AppModel()
        m.entries = [entry("brain", "5.1.0"), entry("brain", "6.1.0"), entry("brain", "6.0.3")]
        m.expandedNames.insert("brain")
        #expect(m.filteredAndGrouped.flatMap(\.entries).count == 3)
    }

    @Test func testVersionsForName() {
        let m = AppModel()
        m.entries = [entry("brain", "5.1.0"), entry("brain", "6.1.0")]
        #expect(m.versions(forName: "brain").count == 2)
        #expect(m.versions(forName: "brain").first?.version == "6.1.0")
    }

    @Test func testVersionsForNameIsSemverOrdered() {
        // 10.0.0 必须排在 2.0.0 之上（按数字而非字符串比较）
        let m = AppModel()
        m.entries = [entry("thing", "2.0.0"), entry("thing", "10.0.0"), entry("thing", "9.5.3")]
        let ordered = m.versions(forName: "thing").map(\.version)
        #expect(ordered == ["10.0.0", "9.5.3", "2.0.0"])
    }

    @Test func testCompareVersionSemantics() {
        #expect(AppModel.compareVersion("10.0.0", "2.0.0") == .orderedDescending)
        #expect(AppModel.compareVersion("2.0.0", "10.0.0") == .orderedAscending)
        #expect(AppModel.compareVersion("2.0.0", "2.0.0") == .orderedSame)
        #expect(AppModel.compareVersion("2.0", "2.0.0") == .orderedSame)
        #expect(AppModel.compareVersion("2.1.0", "2.0.9") == .orderedDescending)
        #expect(AppModel.compareVersion(nil, "0.0.1") == .orderedAscending)
        #expect(AppModel.compareVersion("1.0.0", nil) == .orderedDescending)
        #expect(AppModel.compareVersion(nil, nil) == .orderedSame)
    }

    @Test func testFilteredVersionsRespectsSourceFilter() {
        // 同名 skill 跨来源，过滤为单来源后只有该来源的版本应出现
        let m = AppModel()
        m.entries = [
            entry("dup", "1.0.0", .personal),
            entry("dup", "2.0.0", .personal),
            entry("dup", "3.0.0", .superpowers)
        ]
        m.selectedSources = [.personal]
        let filtered = m.filteredVersions(forName: "dup")
        #expect(filtered.count == 2)
        #expect(filtered.map(\.version) == ["2.0.0", "1.0.0"])
        // 不过滤来源时返回全部
        m.selectedSources = []
        let all = m.filteredVersions(forName: "dup")
        #expect(all.count == 3)
        #expect(all.first?.version == "3.0.0")
    }

    @Test func testFilteredVersionsRespectsQuery() {
        let m = AppModel()
        m.entries = [
            entry("dup", "1.0.0", .personal),
            entry("dup", "2.0.0", .personal)
        ]
        // query 命中 skillDirPath（"/x/dup"）所以仍保留全部
        m.query = "dup"
        #expect(m.filteredVersions(forName: "dup").count == 2)
        // query 命不中则返回空
        m.query = "zzz"
        #expect(m.filteredVersions(forName: "dup").count == 0)
    }
}
