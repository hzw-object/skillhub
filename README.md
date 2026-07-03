<div align="center">

# SkillHub

**A native macOS client for browsing all your local Claude Code skills.**
**一个原生 macOS 客户端，用于浏览本机所有的 Claude Code skills。**

[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)](#)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](#)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-NavigationSplitView-purple)](#)
[![License](https://img.shields.io/badge/license-MIT-green)](#)
[![GitHub stars](https://img.shields.io/github/stars/hzw-object/skillhub?style=social)](https://github.com/hzw-object/skillhub/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/hzw-object/skillhub?style=social)](https://github.com/hzw-object/skillhub/forks)
[![GitHub issues](https://img.shields.io/github/issues/hzw-object/skillhub)](https://github.com/hzw-object/skillhub/issues)

![SkillHub Banner](logo.png)

</div>

---

## 🌐 简体中文

SkillHub 是一个原生 SwiftUI macOS 应用，用于扫描、浏览和管理本机安装的所有 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills。它把你散落在 `~/.claude/skills/` 个人目录与 `~/.claude/plugins/cache/` 各个插件市场下的 skills，统一聚合到一个三栏布局的桌面应用里，配上 Markdown 渲染、语法高亮、脚本预览和一键运行。

### ✨ 功能特性

- **自动扫描本机所有 skills** — 覆盖个人 skills（`~/.claude/skills/`）与已安装插件市场（Superpowers、Frontend Design、Ponytail、GLM Plan Usage 等）的 skills，按来源分组归类。
- **三栏 NavigationSplitView 布局** — 左侧来源侧边栏、中间 skill 列表、右侧详情，符合 macOS 原生体验。
- **多版本折叠/展开** — 同一 skill 的多个版本按语义化版本号（semver）排序，默认折叠为最高版本，可一键展开查看全部历史版本。
- **跨来源同名不合并** — 来自不同来源但同名的 skill 各自独立成组，不会误并。
- **SKILL.md 渲染** — 用 [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) 渲染 Markdown 正文，用 [Highlightr](https://github.com/raspu/Highlightr) 给代码块做语法高亮。
- **目录树浏览** — 以递归 `OutlineGroup` 展示 skill 目录的完整文件结构，点击文件即可查看完整内容。
- **脚本预览与运行** — 支持 `.sh` / `.py` / `.js` 脚本，预览完整源码并一键运行，实时查看 stdout / stderr 与退出码（30 秒超时保护）。
- **来源过滤与搜索** — 侧边栏按来源过滤，顶部搜索框按名称/描述/路径过滤。
- **扫描错误可视化** — 某个根目录扫描失败时，对应来源旁会出现警告图标，不影响其他来源。

### 📸 应用截图

> 主界面：左侧来源侧边栏、中间 skill 列表（带版本折叠/展开）、右侧 SKILL.md 渲染与递归文件树。
>
> _截图待补充。可自行运行 `./scripts/build-app.sh` 后 `open dist/SkillHub.app` 体验。_

| 截图 | 说明 |
|------|------|
| 主界面 | 来源侧边栏 + skill 列表 + SKILL.md 渲染 + 文件树 |
| 版本管理 | 同 skill 多版本折叠/展开，按语义化版本排序 |
| 脚本运行 | `.sh` / `.py` / `.js` 一键运行，查看 stdout/stderr |

### 🏗 架构

```
Sources/SkillHub/
├── SkillHubApp.swift            # 应用入口 (@main)
├── Models/
│   ├── SkillEntry.swift         # 单个 skill 条目模型
│   ├── SkillSource.swift        # 来源枚举 (personal/superpowers/…)
│   ├── SkillGroup.swift         # 来源分组 + (source,name) 组合键
│   └── ScriptFile.swift         # 脚本文件模型 (含完整 content)
├── Services/
│   ├── PathProvider.swift       # 扫描根目录探测与来源归类
│   ├── SkillScanner.swift       # 并发扫描所有根目录
│   ├── SkillMarkdownParser.swift # 解析 SKILL.md front matter
│   ├── ScriptRunner.swift       # 运行脚本 (30s 超时, 输出截断)
│   ├── ScriptResult.swift
│   └── ScanError.swift
├── ViewModels/
│   └── AppModel.swift           # @Observable 全局状态: 过滤/分组/去重
└── Views/
    ├── ContentView.swift        # 三栏 NavigationSplitView 容器
    ├── SidebarView.swift        # 来源侧边栏
    ├── SkillListView.swift      # skill 列表 (版本折叠/展开)
    ├── SkillRowView.swift
    ├── SkillDetailView.swift    # 详情: Markdown + 文件树
    ├── FileTreeView.swift       # 递归目录树 (OutlineGroup)
    ├── MetaInfoCard.swift
    ├── ScriptPreviewSheet.swift
    ├── ScriptResultView.swift
    ├── MarkdownRenderer.swift
    ├── HighlightrCodeSyntaxHighlighter.swift
    └── SkillMarkdownTheme.swift
```

**设计要点：**

- `@Observable` + `@MainActor` 的 `AppModel` 持有全部状态，视图层用 `@Bindable` 绑定。
- `Services` 层纯 Swift、无 UI 依赖，可独立单元测试。
- 按 `(source, name)` 分组 + 同版本去重，解决「跨来源同名误并」与「同版本号重复」两个真实问题。
- 语义化版本比较：按 `.` 切分段、逐段 Int 比较，`10.0.0` 正确排在 `9.5.3` 之上。

### 📦 构建 / 运行 / 测试

```bash
# 构建
swift build

# 运行（调试）
swift run SkillHub

# 打包为 .app（带 ad-hoc 签名，可直接双击运行）
./scripts/build-app.sh
# 产物: dist/SkillHub.app

# 运行测试（CLT-only 环境，无需 Xcode）
./scripts/run-tests.sh
```

> **环境要求：** macOS 14 (Sonoma) 及以上、Swift 5.9+、Command Line Tools。

### 📈 项目统计

| 统计项 | 链接 |
|--------|------|
| ⭐ Stars | [![GitHub stars](https://img.shields.io/github/stars/hzw-object/skillhub?style=flat)](https://github.com/hzw-object/skillhub/stargazers) |
| 🍴 Forks | [![GitHub forks](https://img.shields.io/github/forks/hzw-object/skillhub?style=flat)](https://github.com/hzw-object/skillhub/forks) |
| 🐛 Issues | [![GitHub issues](https://img.shields.io/github/issues/hzw-object/skillhub?style=flat)](https://github.com/hzw-object/skillhub/issues) |
| 📥 Clone | `git clone https://github.com/hzw-object/skillhub.git` |

### 🤝 贡献

欢迎提 Issue 和 PR。请先运行 `./scripts/run-tests.sh` 确保测试通过。

### 📄 许可证

MIT

---

## 🌍 English

SkillHub is a native SwiftUI macOS app for scanning, browsing, and managing all the [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills installed on your machine. It gathers skills scattered across your personal `~/.claude/skills/` directory and the various plugin marketplaces under `~/.claude/plugins/cache/` into a single three-pane desktop app, complete with Markdown rendering, syntax highlighting, script preview, and one-click execution.

### ✨ Features

- **Auto-scans every local skill** — Covers personal skills (`~/.claude/skills/`) and installed plugin marketplaces (Superpowers, Frontend Design, Ponytail, GLM Plan Usage, …), grouped by source.
- **Three-pane NavigationSplitView layout** — Source sidebar on the left, skill list in the middle, details on the right — a native macOS experience.
- **Multi-version folding / expanding** — Multiple versions of the same skill are sorted by semantic version (semver) and collapsed to the highest by default; expand to see the full version history.
- **Cross-source same-name isolation** — Skills with the same name from different sources stay in independent groups; no accidental merging.
- **SKILL.md rendering** — Renders Markdown body with [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) and syntax-highlights code blocks with [Highlightr](https://github.com/raspu/Highlightr).
- **Directory tree browsing** — Shows the skill's full file structure as a recursive `OutlineGroup`; click any file to read its complete content.
- **Script preview & execution** — Supports `.sh` / `.py` / `.js` scripts; preview the full source and run it with one click, watching stdout / stderr and the exit code in real time (30-second timeout).
- **Source filtering & search** — Filter by source in the sidebar; search by name / description / path at the top.
- **Scan-error visibility** — When a root scan fails, a warning icon appears beside that source — without affecting the others.

### 📸 Screenshots

> Main window: source sidebar on the left, skill list in the middle (with version fold/expand), rendered SKILL.md and recursive file tree on the right.
>
> _Screenshots to be added. Run `./scripts/build-app.sh` yourself, then `open dist/SkillHub.app` to try it._

| Screenshot | Description |
|------------|-------------|
| Main window | Source sidebar + skill list + SKILL.md rendering + file tree |
| Version management | Multi-version fold/expand for one skill, sorted by semver |
| Script run | One-click run for `.sh` / `.py` / `.js`, view stdout/stderr |

### 🏗 Architecture

```
Sources/SkillHub/
├── SkillHubApp.swift            # App entry (@main)
├── Models/
│   ├── SkillEntry.swift         # Single skill entry model
│   ├── SkillSource.swift        # Source enum (personal/superpowers/…)
│   ├── SkillGroup.swift         # Source grouping + (source,name) key
│   └── ScriptFile.swift         # Script file model (with full content)
├── Services/
│   ├── PathProvider.swift       # Scan-root discovery & source classification
│   ├── SkillScanner.swift       # Concurrent scan of all roots
│   ├── SkillMarkdownParser.swift # Parse SKILL.md front matter
│   ├── ScriptRunner.swift       # Run scripts (30s timeout, output truncation)
│   ├── ScriptResult.swift
│   └── ScanError.swift
├── ViewModels/
│   └── AppModel.swift           # @Observable global state: filter/group/dedup
└── Views/
    ├── ContentView.swift        # Three-pane NavigationSplitView container
    ├── SidebarView.swift        # Source sidebar
    ├── SkillListView.swift      # Skill list (version fold/expand)
    ├── SkillRowView.swift
    ├── SkillDetailView.swift    # Details: Markdown + file tree
    ├── FileTreeView.swift       # Recursive directory tree (OutlineGroup)
    ├── MetaInfoCard.swift
    ├── ScriptPreviewSheet.swift
    ├── ScriptResultView.swift
    ├── MarkdownRenderer.swift
    ├── HighlightrCodeSyntaxHighlighter.swift
    └── SkillMarkdownTheme.swift
```

**Design highlights:**

- `@Observable` + `@MainActor` `AppModel` holds all state; views bind with `@Bindable`.
- The `Services` layer is pure Swift with no UI dependencies, so it's independently unit-testable.
- Grouping by `(source, name)` plus same-version deduplication resolves two real issues: accidental merging of cross-source same-name skills, and duplicate same-version entries.
- Semantic version comparison: splits on `.`, compares each segment as Int — so `10.0.0` correctly ranks above `9.5.3`.

### 📦 Build / Run / Test

```bash
# Build
swift build

# Run (debug)
swift run SkillHub

# Package as .app (ad-hoc signed, double-clickable)
./scripts/build-app.sh
# Output: dist/SkillHub.app

# Run tests (CLT-only env, no Xcode needed)
./scripts/run-tests.sh
```

> **Requirements:** macOS 14 (Sonoma) or later, Swift 5.9+, Command Line Tools.

### 📈 Project Stats

| Stat | Link |
|------|------|
| ⭐ Stars | [![GitHub stars](https://img.shields.io/github/stars/hzw-object/skillhub?style=flat)](https://github.com/hzw-object/skillhub/stargazers) |
| 🍴 Forks | [![GitHub forks](https://img.shields.io/github/forks/hzw-object/skillhub?style=flat)](https://github.com/hzw-object/skillhub/forks) |
| 🐛 Issues | [![GitHub issues](https://img.shields.io/github/issues/hzw-object/skillhub?style=flat)](https://github.com/hzw-object/skillhub/issues) |
| 📥 Clone | `git clone https://github.com/hzw-object/skillhub.git` |

### 🤝 Contributing

Issues and PRs are welcome. Please run `./scripts/run-tests.sh` to make sure the suite passes first.

### 📄 License

MIT
