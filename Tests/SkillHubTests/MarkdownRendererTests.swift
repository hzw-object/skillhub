import Testing
@testable import SkillHub

@Suite("MarkdownRendererTests") struct MarkdownRendererTests {

    @Test func testStripsStandardFrontMatter() {
        let md = """
        ---
        name: brainstorming
        description: "Use this before creative work."
        ---

        # Brainstorming

        Body paragraph.
        """
        let cleaned = MarkdownRenderer.clean(md)
        #expect(!cleaned.contains("name: brainstorming"))
        #expect(cleaned.hasPrefix("# Brainstorming"))
        #expect(cleaned.contains("Body paragraph."))
    }

    @Test func testStripsPonytailStyleFoldedDescription() {
        // 对应 ponytail SKILL.md：多行折叠标量 + argument-hint + license + 正文
        let md = """
        ---
        name: ponytail
        description: >
          Forces the laziest solution that actually works.
        argument-hint: "[lite|full|ultra]"
        license: MIT
        ---

        # Ponytail

        You are a lazy senior developer.
        """
        let cleaned = MarkdownRenderer.clean(md)
        #expect(!cleaned.contains("name: ponytail"))
        #expect(!cleaned.contains("license: MIT"))
        #expect(cleaned.hasPrefix("# Ponytail"))
        #expect(cleaned.contains("lazy senior developer"))
    }

    @Test func testPreservesMidDocumentThematicBreak() {
        // 正文中的 ---（分隔线）不得被误判为 front matter 闭合
        let md = """
        # Title

        intro

        ---

        after break
        """
        let cleaned = MarkdownRenderer.clean(md)
        #expect(cleaned.contains("# Title"))
        #expect(cleaned.contains("intro"))
        #expect(cleaned.contains("after break"))
        // 仍保留正文中的 ---
        #expect(cleaned.range(of: "---") != nil)
    }

    @Test func testNoFrontMatterReturnsBodyUntouched() {
        let md = "# Just a title\n\nbody"
        let cleaned = MarkdownRenderer.clean(md)
        #expect(cleaned.hasPrefix("# Just a title"))
        #expect(cleaned.contains("body"))
    }

    @Test func testUnclosedFrontMatterKeepsWholeDocument() {
        // 缺失闭合标记：按"不是 front matter"处理，原文返回以免误删
        let md = """
        ---
        name: dangling
        description: "no closer here"
        # Body without closing fence
        """
        let cleaned = MarkdownRenderer.clean(md)
        #expect(cleaned.contains("name: dangling"))
        #expect(cleaned.contains("# Body without closing fence"))
    }

    @Test func testDotDotDotClosesFrontMatter() {
        // YAML 也允许 ... 作为文档结束标记
        let md = """
        ---
        name: yamldots
        ...
        # Body
        """
        let cleaned = MarkdownRenderer.clean(md)
        #expect(!cleaned.contains("yamldots"))
        #expect(cleaned.hasPrefix("# Body"))
    }

    @Test func testCRLFNormalizedBeforeStripping() {
        let md = "---\r\nname: crlf\r\ndescription: \"x\"\r\n---\r\n\r\n# Body\r\n"
        let cleaned = MarkdownRenderer.clean(md)
        #expect(!cleaned.contains("name: crlf"))
        #expect(cleaned.hasPrefix("# Body"))
        #expect(!cleaned.contains("\r"))
    }
}
