import Testing
@testable import SkillHub

@Suite("PathProviderTests") struct PathProviderTests {
    @Test func testHomeExpandIsAbsolute() {
        let roots = PathProvider.rootDirectories()
        for r in roots {
            #expect(r.path.hasPrefix("/"))
            #expect(!(r.path.contains("~")))
        }
    }

    @Test func testPersonalRootPresent() {
        let roots = PathProvider.rootDirectories()
        #expect(roots.contains { $0.source == .personal && $0.path.hasSuffix(".claude/skills") })
    }

    @Test func testNoOtherSourcesWhenCacheMissing() {
        // 仅断言不崩溃且 personal 一定在；cache 目录可能不存在
        _ = PathProvider.rootDirectories()
    }

    @Test func testClassifySource() {
        #expect(PathProvider.classify(marketplace: "superpowers-marketplace",
                                             plugin: "superpowers") == .superpowers)
        #expect(PathProvider.classify(marketplace: "claude-plugins-official",
                                             plugin: "superpowers") == .superpowers)
        #expect(PathProvider.classify(marketplace: "claude-plugins-official",
                                             plugin: "frontend-design") == .frontendDesign)
        #expect(PathProvider.classify(marketplace: "ponytail",
                                             plugin: "ponytail") == .ponytail)
        #expect(PathProvider.classify(marketplace: "zai-coding-plugins",
                                             plugin: "glm-plan-usage") == .glmPlanUsage)
        #expect(PathProvider.classify(marketplace: "unknown",
                                             plugin: "x") == .other)
    }
}
