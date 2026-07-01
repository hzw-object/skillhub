import Testing
@testable import SkillHub

@Suite("SkillMarkdownParserTests") struct SkillMarkdownParserTests {
    @Test func testStandardFrontMatter() {
        let md = """
        ---
        name: brainstorming
        description: "Use this before creative work."
        ---

        # Body
        """
        let fm = SkillMarkdownParser.parse(md)
        #expect(fm.name == "brainstorming")
        #expect(fm.description == "Use this before creative work.")
    }

    @Test func testMultiLineDescriptionBlock() {
        let md = """
        ---
        name: wewrite
        description: |
          第一行
          第二行
        ---
        # Body
        """
        let fm = SkillMarkdownParser.parse(md)
        #expect(fm.name == "wewrite")
        #expect(fm.description == "第一行\n第二行")
    }

    @Test func testNoFrontMatter() {
        let md = "# Just a title\nbody"
        let fm = SkillMarkdownParser.parse(md)
        #expect(fm.name == "")
        #expect(fm.description == "")
    }

    @Test func testBrokenYamlDoesNotThrow() {
        let md = """
        ---
        name: broken
        description: : : :
        ---
        """
        let fm = SkillMarkdownParser.parse(md)
        #expect(fm.name == "broken")
        #expect(!(fm.description.isEmpty)) // 只要不崩溃即可
    }

    @Test func testNameMissing() {
        let md = """
        ---
        description: "no name"
        ---
        """
        let fm = SkillMarkdownParser.parse(md)
        #expect(fm.name == "")
        #expect(fm.description == "no name")
    }
}
