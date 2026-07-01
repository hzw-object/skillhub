# SkillHub

原生 macOS 客户端，浏览本机所有 Claude Code skill。

## 构建 / 运行 / 测试

```bash
swift build
swift run SkillHub
swift test
```

## 架构

SwiftUI + @Observable AppModel + 三栏 NavigationSplitView。
Services 层（PathProvider / SkillScanner / SkillMarkdownParser / ScriptRunner）纯 Swift 可单测。
零外部依赖；Markdown 用 Foundation `AttributedString(markdown:)`。

详见 `docs/superpowers/specs/2026-07-01-mac-skill-viewer-design.md`。
