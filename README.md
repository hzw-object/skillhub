<div align="center">

[简体中文](README.zh-CN.md) | **English**

# SkillHub

**A native macOS client for browsing all your local Claude Code skills.**

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
