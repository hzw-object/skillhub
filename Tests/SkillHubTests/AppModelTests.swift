import Testing
@testable import SkillHub

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
}
