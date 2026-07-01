# SkillHub Mac 客户端实现计划

> **For agentic workers:** Required SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个原生 SwiftUI macOS 应用 SkillHub，扫描本机所有 Claude Code skill 存放位置，三栏布局浏览/搜索/查看 skill 详情（含 Markdown 渲染、目录文件浏览、脚本预览执行）。

**Architecture:** SwiftPM 管理的单 executable target SwiftUI App。`@Observable` 全局 `AppModel` 持有扫描结果，`NavigationSplitView` 三栏（来源侧边栏 / 搜索+分组列表 / 详情）。Services 层做扫描/解析/执行，纯 Swift 可单测；Views 层组合展示。无持久化、无网络。

**Tech Stack:** Swift 5.9+ / macOS 13 Ventura / SwiftUI / Foundation / AppKit（NSWorkspace、NSPasteboard、Process）/ XCTest。零外部依赖（Markdown 渲染用 Foundation 内置 `AttributedString(markdown:)`，替代 spec 中的 Down —— 见 Global Constraints）。

## Global Constraints

- **平台**：macOS 13.0+（`platforms: [.macOS(.v13)]`）。
- **构建系统**：Swift Package Manager（非 Xcode 工程）。命令统一为 `swift build`、`swift test`、`swift run`。
- **测试框架**：XCTest（`swift test`）。不使用 Swift Testing（需 macOS 14 SDK，本计划锁 macOS 13）。
- **Markdown 渲染**：用 Foundation 内置 `AttributedString(markdown:options:)`（macOS 13+ 原生支持 CommonMark 子集），替代 spec 中提到的 `Down` 库。理由：零外部依赖、零构建风险、同为「Markdown → AttributedString」目标。渲染失败回退纯文本 `.monospaced`。
- **并发**：扫描用 `TaskGroup` 并发；`@Observable AppModel` 驱动 UI。
- **命名**：类型用 PascalCase，方法/属性用 camelCase。`SkillSource` 的 `displayName`/`icon` 用中文标签 + SF Symbols。
- **skill 范围**：扫描 `~/.claude/skills/` 与 `~/.claude/plugins/cache/` 下所有 `<marketplace>/<plugin>/<version>/skills` 三层结构，保留多版本（同 `name` 不同路径即不同条目）。
- **路径展开**：`~` 用 `NSHomeDirectory()`，失败回退 `FileManager.default.currentDirectoryPath`。
- **脚本执行安全**：超时 30s；无执行权限时用解释器兜底（`.sh`→`bash`、`.py`→`python3`、`.js`→`node`）；输出截断到 10000 字符。
- **commit 风格**：`feat:`/`test:`/`chore:`/`docs:` 前缀，每个 task 末尾 commit。
- **TDD**：每个有逻辑的任务先写失败测试再实现。

---

## File Structure

```
skillhub/
├── Package.swift                         # SwiftPM 清单
├── Sources/
│   └── SkillHub/
│       ├── SkillHubApp.swift             # @main 入口
│       ├── Models/
│       │   ├── SkillSource.swift          # 来源枚举
│       │   ├── SkillEntry.swift          # skill 数据模型
│       │   ├── ScriptFile.swift          # 脚本模型 + ScriptLanguage
│       │   └── SkillGroup.swift          # 列表分组
│       ├── Services/
│       │   ├── PathProvider.swift         # 根目录定位 + 来源归属
│       │   ├── SkillScanner.swift        # 扫描器
│       │   ├── SkillMarkdownParser.swift # front matter 解析
│       │   ├── ScriptRunner.swift        # 脚本执行
│       │   └── ScriptResult.swift        # 执行结果模型
│       ├── ViewModels/
│       │   └── AppModel.swift            # @Observable 全局状态
│       └── Views/
│           ├── ContentView.swift         # 三栏容器
│           ├── SidebarView.swift        # 来源过滤
│           ├── SkillListView.swift       # 搜索 + 分组列表
│           ├── SkillRowView.swift        # 单行 + 多版本折叠
│           ├── SkillDetailView.swift    # 详情
│           ├── MetaInfoCard.swift        # 元信息卡片
│           ├── MarkdownRenderer.swift    # AttributedString 包装
│           ├── FileTreeView.swift        # 目录文件列表
│           ├── ScriptPreviewSheet.swift  # 执行前预览
│           └── ScriptResultView.swift    # 执行结果
├── Tests/
│   └── SkillHubTests/
│       ├── SkillMarkdownParserTests.swift
│       ├── PathProviderTests.swift
│       ├── SkillScannerTests.swift
│       ├── ScriptFileTests.swift
│       ├── ScriptRunnerTests.swift
│       └── AppModelTests.swift
└── Tests/Fixtures/                       # 假 skill 目录
    ├── standard/SKILL.md
    ├── no-frontmatter/SKILL.md
    ├── multi-line-desc/SKILL.md
    ├── broken-yaml/SKILL.md
    └── with-scripts/
        ├── SKILL.md
        └── scripts/{hello.sh,tool.py,run.js}
```

**职责边界**：
- `Models/`：纯数据，无 I/O，无 SwiftUI 依赖。
- `Services/`：纯 Foundation，可单测，不被 View 直接持有。
- `ViewModels/AppModel`：唯一状态源，组合 Services，被 View 观察。
- `Views/`：纯展示，通过 `@Bindable`/`@State` 绑定 AppModel，不直接调 Services。

---

### Task 1: 初始化 SwiftPM 工程骨架

**Files:**
- Create: `Package.swift`
- Create: `Sources/SkillHub/SkillHubApp.swift`
- Create: `.gitignore`

**Interfaces:**
- Produces: 可编译的空 SwiftUI App；`swift build` 通过。

- [ ] **Step 1: 写 `Package.swift`**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SkillHub",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SkillHub",
            path: "Sources/SkillHub"
        ),
        .testTarget(
            name: "SkillHubTests",
            dependencies: ["SkillHub"],
            path: "Tests/SkillHubTests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
```

- [ ] **Step 2: 写 `Sources/SkillHub/SkillHubApp.swift`**

```swift
import SwiftUI

@main
struct SkillHubApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("SkillHub skeleton")
            .padding()
    }
}
```

- [ ] **Step 3: 写 `.gitignore`**

```
.build/
.swiftpm/
*.xcodeproj/
DerivedData/
```

- [ ] **Step 4: 构建验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources/ .gitignore
git commit -m "chore: init SwiftPM skeleton"
```

---

### Task 2: SkillSource 来源枚举

**Files:**
- Create: `Sources/SkillHub/Models/SkillSource.swift`
- Test: `Tests/SkillHubTests/SkillSourceTests.swift`

**Interfaces:**
- Produces: `enum SkillSource: String, CaseIterable, Identifiable, Hashable`，`rawValue` 为小写蛇形（`personal`/`superpowers`/`frontend_design`/`ponytail`/`glm_plan_usage`/`other`）。`id` 返回 `rawValue`。`allCases` 顺序固定为 `[personal, superpowers, frontendDesign, ponytail, glmPlanUsage, other]`。`displayName: String`、`icon: String`（SF Symbol 名）。

- [ ] **Step 1: 写失败测试 `Tests/SkillHubTests/SkillSourceTests.swift`**

```swift
import XCTest
@testable import SkillHub

final class SkillSourceTests: XCTestCase {
    func testAllCasesOrder() {
        XCTAssertEqual(
            SkillSource.allCases.map(\.rawValue),
            ["personal", "superpowers", "frontend_design", "ponytail", "glm_plan_usage", "other"]
        )
    }

    func testIdIsRawValue() {
        XCTAssertEqual(SkillSource.personal.id, "personal")
    }

    func testDisplayNameNonEmpty() {
        for s in SkillSource.allCases {
            XCTAssertFalse(s.displayName.isEmpty, "\(s) has empty displayName")
        }
    }

    func testIconIsSFSymbolName() {
        for s in SkillSource.allCases {
            XCTAssertFalse(s.icon.isEmpty, "\(s) has empty icon")
        }
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `swift test --filter SkillSourceTests`
Expected: FAIL（`SkillSource` 未定义）

- [ ] **Step 3: 写实现 `Sources/SkillHub/Models/SkillSource.swift`**

```swift
import Foundation

enum SkillSource: String, CaseIterable, Identifiable, Hashable {
    case personal
    case superpowers
    case frontendDesign = "frontend_design"
    case ponytail
    case glmPlanUsage = "glm_plan_usage"
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .personal:       return "个人 Skills"
        case .superpowers:    return "Superpowers"
        case .frontendDesign: return "Frontend Design"
        case .ponytail:       return "Ponytail"
        case .glmPlanUsage:   return "GLM Plan Usage"
        case .other:          return "其他"
        }
    }

    var icon: String {
        switch self {
        case .personal:       return "person.crop.square"
        case .superpowers:    return "bolt.square"
        case .frontendDesign: return "paintbrush.square"
        case .ponytail:       return "sparkles.square"
        case .glmPlanUsage:   return "chart.bar.square"
        case .other:          return "questionmark.square"
        }
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

Run: `swift test --filter SkillSourceTests`
Expected: PASS（4 个测试）

- [ ] **Step 5: Commit**

```bash
git add Sources/SkillHub/Models/SkillSource.swift Tests/SkillHubTests/SkillSourceTests.swift
git commit -m "feat: add SkillSource enum"
```

---

### Task 3: SkillEntry 数据模型

**Files:**
- Create: `Sources/SkillHub/Models/SkillEntry.swift`

**Interfaces:**
- Produces: `struct SkillEntry: Identifiable, Hashable`，字段：`id: String`（绝对路径）、`name: String`、`description: String`、`source: SkillSource`、`skillDirPath: String`、`skillMdPath: String`、`version: String?`、`sizeBytes: Int`、`fileCount: Int`。`skillMdContent` **不在模型中**（按需读取，缓存于 AppModel）。

- [ ] **Step 1: 写实现**

```swift
import Foundation

struct SkillEntry: Identifiable, Hashable {
    let id: String            // 绝对路径，天然唯一且区分多版本
    let name: String         // front matter 的 name，无则用目录名
    let description: String  // front matter 的 description
    let source: SkillSource
    let skillDirPath: String // skill 目录绝对路径
    let skillMdPath: String  // SKILL.md 绝对路径
    let version: String?     // 路径中的版本号（如 "6.1.0"），无则 nil
    let sizeBytes: Int       // skill 目录总大小
    let fileCount: Int       // skill 目录下文件总数
}
```

- [ ] **Step 2: 构建验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/SkillHub/Models/SkillEntry.swift
git commit -m "feat: add SkillEntry model"
```

---

### Task 4: ScriptFile + ScriptLanguage 模型

**Files:**
- Create: `Sources/SkillHub/Models/ScriptFile.swift`
- Test: `Tests/SkillHubTests/ScriptFileTests.swift`

**Interfaces:**
- Produces: `enum ScriptLanguage: String, CaseIterable { case shell, python, node, other }`；`static func from(pathExtension: String) -> ScriptLanguage`。
- Produces: `struct ScriptFile: Identifiable, Hashable`，字段：`id: String`（绝对路径）、`name: String`、`relativePath: String`、`sizeBytes: Int`、`language: ScriptLanguage`、`contentPreview: String`（前 50 行）。
- Produces: `static func make(at absolutePath: String, skillDirPath: String) throws -> ScriptFile` —— 读文件大小、前 50 行内容、按扩展名判语言、计算相对路径。

- [ ] **Step 1: 写失败测试 `Tests/SkillHubTests/ScriptFileTests.swift`**

```swift
import XCTest
@testable import SkillHub

final class ScriptFileTests: XCTestCase {
    func testLanguageFromExtension() {
        XCTAssertEqual(ScriptLanguage.from(pathExtension: "sh"), .shell)
        XCTAssertEqual(ScriptLanguage.from(pathExtension: "py"), .python)
        XCTAssertEqual(ScriptLanguage.from(pathExtension: "js"), .node)
        XCTAssertEqual(ScriptLanguage.from(pathExtension: "txt"), .other)
        XCTAssertEqual(ScriptLanguage.from(pathExtension: ""), .other)
    }

    func testMakeBuildsFields() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("skill-\(UUID().uuidString)/scripts/hello.sh")
        try FileManager.default.createDirectory(at: temp.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let lines = (0..<60).map { "echo line \($0)" }.joined(separator: "\n")
        try lines.write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp.deletingLastPathComponent().deletingLastPathComponent()) }

        let skillDir = temp.deletingLastPathComponent().deletingLastPathComponent().path
        let f = try ScriptFile.make(at: temp.path, skillDirPath: skillDir)
        XCTAssertEqual(f.name, "hello.sh")
        XCTAssertEqual(f.language, .shell)
        XCTAssertEqual(f.relativePath, "scripts/hello.sh")
        XCTAssertEqual(f.contentPreview.split(separator: "\n").count, 50)
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `swift test --filter ScriptFileTests`
Expected: FAIL（`ScriptLanguage`/`ScriptFile` 未定义）

- [ ] **Step 3: 写实现 `Sources/SkillHub/Models/ScriptFile.swift`**

```swift
import Foundation

enum ScriptLanguage: String, CaseIterable {
    case shell, python, node, other

    static func from(pathExtension: String) -> ScriptLanguage {
        switch pathExtension.lowercased() {
        case "sh", "bash":  return .shell
        case "py":          return .python
        case "js":          return .node
        default:           return .other
        }
    }

    var interpreter: String? {
        switch self {
        case .shell:  return "/bin/bash"
        case .python: return "/usr/bin/env python3"
        case .node:   return "/usr/bin/env node"
        case .other:  return nil
        }
    }
}

struct ScriptFile: Identifiable, Hashable {
    let id: String             // 绝对路径
    let name: String           // 文件名
    let relativePath: String  // 相对 skill 目录
    let sizeBytes: Int
    let language: ScriptLanguage
    let contentPreview: String  // 前 50 行

    static func make(at absolutePath: String, skillDirPath: String) throws -> ScriptFile {
        let url = URL(fileURLWithPath: absolutePath)
        let name = url.lastPathComponent
        let sizeBytes = (try? FileManager.default.attributesOfItem(atPath: absolutePath)
                            [.size] as? Int) ?? 0
        let language = ScriptLanguage.from(pathExtension: url.pathExtension)
        let relativePath: String = {
            let skillDir = URL(fileURLWithPath: skillDirPath)
            return url.path.replacingOccurrences(of: skillDir.path + "/", with: "")
        }()
        let contentPreview = ScriptFile.readFirst50Lines(at: absolutePath)
        return ScriptFile(id: absolutePath, name: name, relativePath: relativePath,
                          sizeBytes: sizeBytes, language: language,
                          contentPreview: contentPreview)
    }

    private static func readFirst50Lines(at path: String) -> String {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let text = String(data: data, encoding: .utf8) else { return "" }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.prefix(50).joined(separator: "\n")
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

Run: `swift test --filter ScriptFileTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/SkillHub/Models/ScriptFile.swift Tests/SkillHubTests/ScriptFileTests.swift
git commit -m "feat: add ScriptFile and ScriptLanguage"
```

---

### Task 5: SkillGroup 列表分组模型

**Files:**
- Create: `Sources/SkillHub/Models/SkillGroup.swift`

**Interfaces:**
- Produces: `struct SkillGroup: Identifiable`，`let source: SkillSource`、`let entries: [SkillEntry]`、`var id: String { source.rawValue }`。

- [ ] **Step 1: 写实现**

```swift
import Foundation

struct SkillGroup: Identifiable {
    let source: SkillSource
    let entries: [SkillEntry]
    var id: String { source.rawValue }
}
```

- [ ] **Step 2: 构建验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/SkillHub/Models/SkillGroup.swift
git commit -m "feat: add SkillGroup model"
```

---

### Task 6: SkillMarkdownParser（YAML front matter）

**Files:**
- Create: `Sources/SkillHub/Services/SkillMarkdownParser.swift`
- Test: `Tests/SkillHubTests/SkillMarkdownParserTests.swift`

**Interfaces:**
- Produces: `struct SkillFrontMatter { let name: String; let description: String }`
- Produces: `enum SkillMarkdownParser { static func parse(_ md: String) -> SkillFrontMatter }` —— 解析首部 `---\n...\n---\n` 块，提取 `name:`、`description:`（支持单行与 `|` 块标量多行）。损坏/无 front matter 时 `name` 回退空、`description` 空，不抛异常。

- [ ] **Step 1: 写失败测试 `Tests/SkillHubTests/SkillMarkdownParserTests.swift`**

```swift
import XCTest
@testable import SkillHub

final class SkillMarkdownParserTests: XCTestCase {
    func testStandardFrontMatter() {
        let md = """
        ---
        name: brainstorming
        description: "Use this before creative work."
        ---

        # Body
        """
        let fm = SkillMarkdownParser.parse(md)
        XCTAssertEqual(fm.name, "brainstorming")
        XCTAssertEqual(fm.description, "Use this before creative work.")
    }

    func testMultiLineDescriptionBlock() {
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
        XCTAssertEqual(fm.name, "wewrite")
        XCTAssertEqual(fm.description, "第一行\n第二行")
    }

    func testNoFrontMatter() {
        let md = "# Just a title\nbody"
        let fm = SkillMarkdownParser.parse(md)
        XCTAssertEqual(fm.name, "")
        XCTAssertEqual(fm.description, "")
    }

    func testBrokenYamlDoesNotThrow() {
        let md = """
        ---
        name: broken
        description: : : :
        ---
        """
        let fm = SkillMarkdownParser.parse(md)
        XCTAssertEqual(fm.name, "broken")
        XCTAssertFalse(fm.description.isEmpty == false) // 只要不崩溃即可
    }

    func testNameMissing() {
        let md = """
        ---
        description: "no name"
        ---
        """
        let fm = SkillMarkdownParser.parse(md)
        XCTAssertEqual(fm.name, "")
        XCTAssertEqual(fm.description, "no name")
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `swift test --filter SkillMarkdownParserTests`
Expected: FAIL（`SkillMarkdownParser` 未定义）

- [ ] **Step 3: 写实现 `Sources/SkillHub/Services/SkillMarkdownParser.swift`**

```swift
import Foundation

struct SkillFrontMatter {
    let name: String
    let description: String
}

enum SkillMarkdownParser {
    static func parse(_ md: String) -> SkillFrontMatter {
        var name = ""
        var description = ""

        let lines = md.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return SkillFrontMatter(name: "", description: "")
        }

        var i = 1
        while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces) != "---" {
            let line = lines[i]
            if let kv = parseLine(line) {
                if kv.key == "name" { name = kv.value }
                else if kv.key == "description" {
                    if kv.value.isEmpty && line.contains("|") {
                        // 块标量：后续缩进行直到 ---
                        var block: [String] = []
                        var j = i + 1
                        while j < lines.count && lines[j].trimmingCharacters(in: .whitespaces) != "---"
                              && (lines[j].hasPrefix(" ") || lines[j].hasPrefix("\t")) {
                            block.append(lines[j].trimmingCharacters(in: .whitespaces))
                            j += 1
                        }
                        description = block.joined(separator: "\n")
                        i = j - 1
                    } else {
                        description = kv.value
                    }
                }
            }
            i += 1
        }
        return SkillFrontMatter(name: name, description: description)
    }

    private static func parseLine(_ line: String) -> (key: String, value: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let colonIdx = trimmed.firstIndex(of: ":") else { return nil }
        let key = String(trimmed[..<colonIdx]).trimmingCharacters(in: .whitespaces)
        var value = String(trimmed[trimmed.index(after: colonIdx)...])
            .trimmingCharacters(in: .whitespaces)
        // 去引号
        if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
            value = String(value.dropFirst().dropLast())
        }
        // 去掉块标量标记 `|`
        if value == "|" { value = "" }
        return (key, value)
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

Run: `swift test --filter SkillMarkdownParserTests`
Expected: PASS（5 个测试）

- [ ] **Step 5: Commit**

```bash
git add Sources/SkillHub/Services/SkillMarkdownParser.swift Tests/SkillHubTests/SkillMarkdownParserTests.swift
git commit -m "feat: add SkillMarkdownParser for YAML front matter"
```

---

### Task 7: PathProvider（根目录 + 来源归属）

**Files:**
- Create: `Sources/SkillHub/Services/PathProvider.swift`
- Test: `Tests/SkillHubTests/PathProviderTests.swift`

**Interfaces:**
- Produces: `struct SkillRoot { let path: String; let source: SkillSource }`
- Produces: `enum PathProvider { static func rootDirectories() -> [SkillRoot] }` —— 返回 `~/.claude/skills/`（`personal`）+ `~/.claude/plugins/cache/` 下所有 `<marketplace>/<plugin>/<version>/skills` 三层结构。
- 来源归属：`superpowers-marketplace`/`claude-plugins-official` 且 plugin=`superpowers` → `.superpowers`；`claude-plugins-official` 且 plugin=`frontend-design` → `.frontendDesign`；`ponytail` 且 plugin=`ponytail` → `.ponytail`；`zai-coding-plugins` 且 plugin=`glm-plan-usage` → `.glmPlanUsage`；其余 → `.other`。
- `~` 用 `NSHomeDirectory()` 展开；不存在目录被跳过（不抛异常）。
- Ponytail 的 `.openclaw/skills` 子目录作为独立根加入，归属 `.ponytail`。

- [ ] **Step 1: 写失败测试 `Tests/SkillHubTests/PathProviderTests.swift`**

```swift
import XCTest
@testable import SkillHub

final class PathProviderTests: XCTestCase {
    func testHomeExpandIsAbsolute() {
        let roots = PathProvider.rootDirectories()
        for r in roots {
            XCTAssertTrue(r.path.hasPrefix("/"), "\(r.path) not absolute")
            XCTAssertFalse(r.path.contains("~"), "\(r.path) contains ~")
        }
    }

    func testPersonalRootPresent() {
        let roots = PathProvider.rootDirectories()
        XCTAssertTrue(roots.contains { $0.source == .personal && $0.path.hasSuffix(".claude/skills") })
    }

    func testNoOtherSourcesWhenCacheMissing() {
        // 仅断言不崩溃且 personal 一定在；cache 目录可能不存在
        _ = PathProvider.rootDirectories()
    }

    func testClassifySource() {
        XCTAssertEqual(PathProvider.classify(marketplace: "superpowers-marketplace",
                                             plugin: "superpowers"), .superpowers)
        XCTAssertEqual(PathProvider.classify(marketplace: "claude-plugins-official",
                                             plugin: "superpowers"), .superpowers)
        XCTAssertEqual(PathProvider.classify(marketplace: "claude-plugins-official",
                                             plugin: "frontend-design"), .frontendDesign)
        XCTAssertEqual(PathProvider.classify(marketplace: "ponytail",
                                             plugin: "ponytail"), .ponytail)
        XCTAssertEqual(PathProvider.classify(marketplace: "zai-coding-plugins",
                                             plugin: "glm-plan-usage"), .glmPlanUsage)
        XCTAssertEqual(PathProvider.classify(marketplace: "unknown",
                                             plugin: "x"), .other)
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `swift test --filter PathProviderTests`
Expected: FAIL（`PathProvider` 未定义）

- [ ] **Step 3: 写实现 `Sources/SkillHub/Services/PathProvider.swift`**

```swift
import Foundation

struct SkillRoot {
    let path: String
    let source: SkillSource
}

enum PathProvider {
    static func rootDirectories() -> [SkillRoot] {
        var roots: [SkillRoot] = []
        let home = NSHomeDirectory()
        let personal = home + "/.claude/skills"
        if FileManager.default.fileExists(atPath: personal) {
            roots.append(SkillRoot(path: personal, source: .personal))
        }

        let cacheBase = home + "/.claude/plugins/cache"
        guard FileManager.default.fileExists(atPath: cacheBase) else { return roots }

        let fm = FileManager.default
        guard let marketplaces = try? fm.contentsOfDirectory(atPath: cacheBase) else { return roots }
        for marketplace in marketplaces {
            let mpPath = cacheBase + "/" + marketplace
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: mpPath, isDirectory: &isDir), isDir.boolValue else { continue }
            guard let plugins = try? fm.contentsOfDirectory(atPath: mpPath) else { continue }
            for plugin in plugins {
                let plPath = mpPath + "/" + plugin
                guard fm.fileExists(atPath: plPath, isDirectory: &isDir), isDir.boolValue else { continue }
                guard let versions = try? fm.contentsOfDirectory(atPath: plPath) else { continue }
                let source = classify(marketplace: marketplace, plugin: plugin)
                for version in versions {
                    let vPath = plPath + "/" + version + "/skills"
                    if fm.fileExists(atPath: vPath, isDirectory: &isDir), isDir.boolValue {
                        roots.append(SkillRoot(path: vPath, source: source))
                    }
                    // ponytail .openclaw/skills 特例
                    let openclaw = plPath + "/" + version + "/.openclaw/skills"
                    if fm.fileExists(atPath: openclaw, isDirectory: &isDir), isDir.boolValue {
                        roots.append(SkillRoot(path: openclaw, source: source))
                    }
                }
            }
        }
        return roots
    }

    static func classify(marketplace: String, plugin: String) -> SkillSource {
        switch (marketplace, plugin) {
        case ("superpowers-marketplace", "superpowers"),
             ("claude-plugins-official", "superpowers"):
            return .superpowers
        case ("claude-plugins-official", "frontend-design"):
            return .frontendDesign
        case ("ponytail", "ponytail"):
            return .ponytail
        case ("zai-coding-plugins", "glm-plan-usage"):
            return .glmPlanUsage
        default:
            return .other
        }
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

Run: `swift test --filter PathProviderTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/SkillHub/Services/PathProvider.swift Tests/SkillHubTests/PathProviderTests.swift
git commit -m "feat: add PathProvider for skill root discovery"
```

---

### Task 8: SkillScanner 扫描器

**Files:**
- Create: `Sources/SkillHub/Services/SkillScanner.swift`
- Test: `Tests/SkillHubTests/SkillScannerTests.swift`
- Test fixtures: `Tests/Fixtures/{standard,no-frontmatter,multi-line-desc,broken-yaml,with-scripts}/SKILL.md` 及 `with-scripts/scripts/*`

**Interfaces:**
- Consumes: `PathProvider.rootDirectories() -> [SkillRoot]`、`SkillMarkdownParser.parse(_:) -> SkillFrontMatter`
- Produces: `final class SkillScanner { func scan() async -> [SkillEntry] }` —— 并发扫描各根，对每个含 `SKILL.md` 的子目录构造 `SkillEntry`，多版本保留。`version` 从根路径中的 `<version>/skills` 段解析（匹配 `\d+\.\d+\.\d+`，无则 nil）。`sizeBytes`/`fileCount` 递归统计。
- Produces: `static func scanRoot(_ root: SkillRoot) -> [SkillEntry]`（便于单测注入固定根）。

- [ ] **Step 1: 写 fixtures**

`Tests/Fixtures/standard/SKILL.md`:
```
---
name: standard-skill
description: "A standard skill."
---
# Body
```

`Tests/Fixtures/no-frontmatter/SKILL.md`:
```
# No frontmatter here
body text
```

`Tests/Fixtures/multi-line-desc/SKILL.md`:
```
---
name: multi
description: |
  line one
  line two
---
```

`Tests/Fixtures/broken-yaml/SKILL.md`:
```
---
name: broken
description: : : :
---
```

`Tests/Fixtures/with-scripts/SKILL.md`:
```
---
name: scripted
description: "has scripts"
---
```
`Tests/Fixtures/with-scripts/scripts/hello.sh`:
```
#!/bin/bash
echo hi
```
`Tests/Fixtures/with-scripts/scripts/tool.py`:
```
print("x")
```
`Tests/Fixtures/with-scripts/scripts/run.js`:
```
console.log("y")
```

- [ ] **Step 2: 写失败测试 `Tests/SkillHubTests/SkillScannerTests.swift`**

```swift
import XCTest
@testable import SkillHub

final class SkillScannerTests: XCTestCase {
    func testScanStandardRoot() throws {
        let fixtures = fixturesRoot()
        let root = SkillRoot(path: fixtures, source: .personal)
        let entries = SkillScanner.scanRoot(root)
        XCTAssertTrue(entries.contains { $0.name == "standard-skill" })
        XCTAssertTrue(entries.contains { $0.name == "multi" })
        XCTAssertTrue(entries.contains { $0.name == "scripted" })
    }

    func testNoFrontMatterUsesDirName() throws {
        let fixtures = fixturesRoot()
        let root = SkillRoot(path: fixtures, source: .personal)
        let entries = SkillScanner.scanRoot(root)
        let noFm = entries.first { $0.skillDirPath.contains("no-frontmatter") }
        XCTAssertNotNil(noFm)
        XCTAssertEqual(noFm?.name, "no-frontmatter")
    }

    func testBrokenYamlDoesNotCrash() throws {
        let fixtures = fixturesRoot()
        let root = SkillRoot(path: fixtures, source: .personal)
        _ = SkillScanner.scanRoot(root) // 不崩溃即通过
    }

    func testSizeAndFileCount() throws {
        let fixtures = fixturesRoot()
        let root = SkillRoot(path: fixtures, source: .personal)
        let entries = SkillScanner.scanRoot(root)
        let scripted = entries.first { $0.name == "scripted" }
        XCTAssertNotNil(scripted)
        XCTAssertGreaterThan(scripted?.fileCount ?? 0, 1) // SKILL.md + 3 scripts
        XCTAssertGreaterThan(scripted?.sizeBytes ?? 0, 0)
    }

    private func fixturesRoot() -> String {
        // Bundle.module 由 .copy("Fixtures") 注入
        let url = Bundle(for: type(of: self)).resourceURL?
            .appendingPathComponent("Fixtures")
        return url?.path ?? ""
    }
}
```

- [ ] **Step 3: 运行测试，确认失败**

Run: `swift test --filter SkillScannerTests`
Expected: FAIL（`SkillScanner` 未定义）

- [ ] **Step 4: 写实现 `Sources/SkillHub/Services/SkillScanner.swift`**

```swift
import Foundation

final class SkillScanner {
    func scan() async -> [SkillEntry] {
        let roots = PathProvider.rootDirectories()
        return await withTaskGroup(of: [SkillEntry].self) { group in
            for root in roots {
                group.addTask { SkillScanner.scanRoot(root) }
            }
            var all: [SkillEntry] = []
            for await batch in group {
                all.append(contentsOf: batch)
            }
            return all.sorted { lhs, rhs in
                if lhs.source.rawValue != rhs.source.rawValue {
                    return lhs.source.rawValue < rhs.source.rawValue
                }
                if lhs.name != rhs.name { return lhs.name < rhs.name }
                return (lhs.version ?? "") > (rhs.version ?? "")
            }
        }
    }

    static func scanRoot(_ root: SkillRoot) -> [SkillEntry] {
        let fm = FileManager.default
        guard let subdirs = try? fm.contentsOfDirectory(atPath: root.path) else { return [] }
        var entries: [SkillEntry] = []
        var isDir: ObjCBool = false
        for sub in subdirs {
            let dir = root.path + "/" + sub
            guard fm.fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue else { continue }
            let md = dir + "/SKILL.md"
            guard fm.fileExists(atPath: md) else { continue }
            let content = (try? String(contentsOfFile: md, encoding: .utf8)) ?? ""
            let fm_ = SkillMarkdownParser.parse(content)
            let name = fm_.name.isEmpty ? sub : fm_.name
            let (size, count) = directoryStats(at: dir)
            entries.append(SkillEntry(
                id: dir, name: name, description: fm_.description,
                source: root.source, skillDirPath: dir, skillMdPath: md,
                version: versionFrom(path: root.path),
                sizeBytes: size, fileCount: count
            ))
        }
        return entries
    }

    private static func directoryStats(at path: String) -> (Int, Int) {
        var size = 0
        var count = 0
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: path) else { return (0, 0) }
        while let item = enumerator.nextObject() as? String {
            let full = path + "/" + item
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: full, isDirectory: &isDir), !isDir.boolValue {
                count += 1
                if let s = (try? fm.attributesOfItem(atPath: full)[.size]) as? Int {
                    size += s
                }
            }
        }
        return (size, count)
    }

    private static func versionFrom(path: String) -> String? {
        // 路径形如 .../<marketplace>/<plugin>/<version>/skills
        let comps = path.split(separator: "/").map(String.init)
        guard let vIdx = comps.lastIndex(of: "skills").flatMap({ $0 - 1 }) else { return nil }
        let v = comps[vIdx]
        let pattern = #"^\d+\.\d+\.\d+$"#
        return v.range(of: pattern, options: .regularExpression) != nil ? v : nil
    }
}
```

- [ ] **Step 5: 运行测试，确认通过**

Run: `swift test --filter SkillScannerTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add Sources/SkillHub/Services/SkillScanner.swift Tests/SkillHubTests/SkillScannerTests.swift Tests/Fixtures/
git commit -m "feat: add SkillScanner"
```

---

### Task 9: ScriptResult + ScriptRunner

**Files:**
- Create: `Sources/SkillHub/Services/ScriptResult.swift`
- Create: `Sources/SkillHub/Services/ScriptRunner.swift`
- Test: `Tests/SkillHubTests/ScriptRunnerTests.swift`

**Interfaces:**
- Produces: `struct ScriptResult { let stdout: String; let stderr: String; let exitCode: Int; let timedOut: Bool; let truncated: Bool }`
- Produces: `final class ScriptRunner { static func run(script: ScriptFile) -> ScriptResult }` —— 30s 超时；`script.language.interpreter` 非空时 `interpreter scriptPath`，否则直接执行 `scriptPath`；输出截断 10000 字符，`truncated` 标记。

- [ ] **Step 1: 写失败测试 `Tests/SkillHubTests/ScriptRunnerTests.swift`**

```swift
import XCTest
@testable import SkillHub

final class ScriptRunnerTests: XCTestCase {
    func testEchoSuccess() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("echo-\(UUID().uuidString).sh")
        try "#!/bin/bash\necho hello".write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp) }
        let sf = ScriptFile(id: temp.path, name: temp.lastPathComponent,
                            relativePath: temp.lastPathComponent, sizeBytes: 0,
                            language: .shell, contentPreview: "")
        let r = ScriptRunner.run(script: sf)
        XCTAssertEqual(r.exitCode, 0)
        XCTAssertTrue(r.stdout.contains("hello"))
        XCTAssertFalse(r.timedOut)
    }

    func testNonZeroExit() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("exit-\(UUID().uuidString).sh")
        try "#!/bin/bash\nexit 3".write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp) }
        let sf = ScriptFile(id: temp.path, name: temp.lastPathComponent,
                            relativePath: temp.lastPathComponent, sizeBytes: 0,
                            language: .shell, contentPreview: "")
        let r = ScriptRunner.run(script: sf)
        XCTAssertEqual(r.exitCode, 3)
        XCTAssertFalse(r.timedOut)
    }

    func testNoPermissionUsesInterpreter() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("noperm-\(UUID().uuidString).sh")
        try "#!/bin/bash\necho works".write(to: temp, atomically: true, encoding: .utf8)
        // 不设置 +x
        defer { try? FileManager.default.removeItem(at: temp) }
        let sf = ScriptFile(id: temp.path, name: temp.lastPathComponent,
                            relativePath: temp.lastPathComponent, sizeBytes: 0,
                            language: .shell, contentPreview: "")
        let r = ScriptRunner.run(script: sf)
        XCTAssertEqual(r.exitCode, 0)
        XCTAssertTrue(r.stdout.contains("works"))
    }

    func testLargeOutputTruncated() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("big-\(UUID().uuidString).sh")
        let body = "#!/bin/bash\n" + (0..<20000).map { "echo line \($0)" }.joined(separator: "\n")
        try body.write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp) }
        let sf = ScriptFile(id: temp.path, name: temp.lastPathComponent,
                            relativePath: temp.lastPathComponent, sizeBytes: 0,
                            language: .shell, contentPreview: "")
        let r = ScriptRunner.run(script: sf)
        XCTAssertTrue(r.truncated)
        XCTAssertLessThanOrEqual(r.stdout.count, 10000 + 200) // 截断后可能略多于 10000（行尾），留余量
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `swift test --filter ScriptRunnerTests`
Expected: FAIL（`ScriptRunner`/`ScriptResult` 未定义）

- [ ] **Step 3: 写 `Sources/SkillHub/Services/ScriptResult.swift`**

```swift
import Foundation

struct ScriptResult {
    let stdout: String
    let stderr: String
    let exitCode: Int
    let timedOut: Bool
    let truncated: Bool
}
```

- [ ] **Step 4: 写 `Sources/SkillHub/Services/ScriptRunner.swift`**

```swift
import Foundation

final class ScriptRunner {
    static let maxOutput = 10_000

    static func run(script: ScriptFile) -> ScriptResult {
        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()
        if let interp = script.language.interpreter {
            process.launchPath = "/bin/sh"
            process.arguments = ["-c", "\(interp) \"\(script.id)\""]
        } else {
            process.launchPath = script.id
            process.arguments = []
        }
        process.standardOutput = outPipe
        process.standardError = errPipe

        let outData = NSMutableData()
        let errData = NSMutableData()
        let outHandle = outPipe.fileHandleForReading
        let errHandle = errPipe.fileHandleForReading
        outHandle.readabilityHandler = { outData.append($0.availableData) }
        errHandle.readabilityHandler = { errData.append($0.availableData) }

        do {
            try process.run()
        } catch {
            return ScriptResult(stdout: "", stderr: error.localizedDescription,
                                 exitCode: -1, timedOut: false, truncated: false)
        }

        let deadline = Date().addingTimeInterval(30)
        var timedOut = false
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }
        if process.isRunning {
            process.terminate()
            timedOut = true
        }
        process.waitUntilExit()
        outHandle.readabilityHandler = nil
        errHandle.readabilityHandler = nil

        let (outStr, outTrunc) = truncate(String(data: outData as Data, encoding: .utf8) ?? "")
        let (errStr, errTrunc) = truncate(String(data: errData as Data, encoding: .utf8) ?? "")
        return ScriptResult(stdout: outStr, stderr: errStr,
                            exitCode: Int(process.terminationStatus),
                            timedOut: timedOut, truncated: outTrunc || errTrunc)
    }

    private static func truncate(_ s: String) -> (String, Bool) {
        if s.count <= maxOutput { return (s, false) }
        let end = s.index(s.startIndex, offsetBy: maxOutput)
        return (String(s[s.startIndex..<end]), true)
    }
}
```

- [ ] **Step 5: 运行测试，确认通过**

Run: `swift test --filter ScriptRunnerTests`
Expected: PASS（注意 `testLargeOutputTruncated` 可能较慢，~1-2s）

- [ ] **Step 6: Commit**

```bash
git add Sources/SkillHub/Services/ScriptResult.swift Sources/SkillHub/Services/ScriptRunner.swift Tests/SkillHubTests/ScriptRunnerTests.swift
git commit -m "feat: add ScriptRunner with timeout and truncation"
```

---

### Task 10: AppModel（@Observable 状态）

**Files:**
- Create: `Sources/SkillHub/ViewModels/AppModel.swift`
- Test: `Tests/SkillHubTests/AppModelTests.swift`

**Interfaces:**
- Produces: `@Observable final class AppModel`：
  - `var entries: [SkillEntry] = []`
  - `var selectedEntryID: String?`
  - `var query: String = ""`
  - `var selectedSources: Set<SkillSource> = []`（空=全部）
  - `var loading: Bool = false`
  - `var expandedNames: Set<String> = []`
  - `var lastScanDate: Date?`
  - `private var skillMdCache: [String: String] = [:]`
  - `var filteredAndGrouped: [SkillGroup]`（计算属性：先按 `selectedSources` 过滤，再按 `query` 模糊匹配 name/description/skillDirPath，最后按 source 分组、组内排序）
  - `func scan() async`（调 `SkillScanner().scan()`，置 `entries`、`lastScanDate`）
  - `func refresh() async`（等同 `scan()`）
  - `func loadSkillMd(for entry: SkillEntry) -> String`（带缓存）
- 多版本折叠：`filteredAndGrouped` 返回的每个 `SkillGroup.entries` 按 `name` 聚合，默认只保留每个 name 的最新版本（`version` 降序）；`expandedNames` 包含某 name 时返回该 name 的全部版本。`AppModel` 另提供 `func versions(forName: String) -> [SkillEntry]` 辅助。

- [ ] **Step 1: 写失败测试 `Tests/SkillHubTests/AppModelTests.swift`**

```swift
import XCTest
@testable import SkillHub

final class AppModelTests: XCTestCase {
    private func entry(_ name: String, _ version: String?, _ source: SkillSource = .personal) -> SkillEntry {
        SkillEntry(id: "/x/\(name)/\(version ?? "0")", name: name, description: "d",
                   source: source, skillDirPath: "/x/\(name)",
                   skillMdPath: "/x/\(name)/SKILL.md", version: version,
                   sizeBytes: 0, fileCount: 0)
    }

    func testSearchByName() {
        let m = AppModel()
        m.entries = [entry("alpha", nil), entry("beta", nil)]
        m.query = "alp"
        XCTAssertEqual(m.filteredAndGrouped.flatMap(\.entries).map(\.name), ["alpha"])
    }

    func testSourceFilter() {
        let m = AppModel()
        m.entries = [entry("a", nil, .personal), entry("b", nil, .superpowers)]
        m.selectedSources = [.superpowers]
        XCTAssertEqual(m.filteredAndGrouped.flatMap(\.entries).map(\.name), ["b"])
    }

    func testEmptySourcesMeansAll() {
        let m = AppModel()
        m.entries = [entry("a", nil, .personal), entry("b", nil, .superpowers)]
        XCTAssertEqual(m.filteredAndGrouped.flatMap(\.entries).count, 2)
    }

    func testMultiVersionFoldedByDefault() {
        let m = AppModel()
        m.entries = [entry("brain", "5.1.0"), entry("brain", "6.1.0"), entry("brain", "6.0.3")]
        let names = m.filteredAndGrouped.flatMap(\.entries).map(\.name)
        XCTAssertEqual(names, ["brain"])            // 折叠为一个
        XCTAssertEqual(m.filteredAndGrouped.flatMap(\.entries).first?.version, "6.1.0")
    }

    func testMultiVersionExpanded() {
        let m = AppModel()
        m.entries = [entry("brain", "5.1.0"), entry("brain", "6.1.0"), entry("brain", "6.0.3")]
        m.expandedNames.insert("brain")
        XCTAssertEqual(m.filteredAndGrouped.flatMap(\.entries).count, 3)
    }

    func testVersionsForName() {
        let m = AppModel()
        m.entries = [entry("brain", "5.1.0"), entry("brain", "6.1.0")]
        XCTAssertEqual(m.versions(forName: "brain").count, 2)
        XCTAssertEqual(m.versions(forName: "brain").first?.version, "6.1.0")
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `swift test --filter AppModelTests`
Expected: FAIL（`AppModel` 未定义）

- [ ] **Step 3: 写实现 `Sources/SkillHub/ViewModels/AppModel.swift`**

```swift
import Foundation
import Observation

@Observable
final class AppModel {
    var entries: [SkillEntry] = []
    var selectedEntryID: String?
    var query: String = ""
    var selectedSources: Set<SkillSource> = []
    var loading: Bool = false
    var expandedNames: Set<String> = []
    var lastScanDate: Date?
    var scanErrors: [String] = []
    private var skillMdCache: [String: String] = [:]

    var filteredAndGrouped: [SkillGroup] {
        let filtered = entries.filter { e in
            (selectedSources.isEmpty || selectedSources.contains(e.source))
            && matchesQuery(e)
        }
        // 多版本折叠
        var collapsed: [SkillEntry] = []
        var byName: [String: [SkillEntry]] = Dictionary(grouping: filtered, by: \.name)
        for name in byName.keys.sorted() {
            let versions = byName[name]!.sorted { ($0.version ?? "") > ($1.version ?? "") }
            if expandedNames.contains(name) {
                collapsed.append(contentsOf: versions)
            } else {
                collapsed.append(versions.first!)
            }
        }
        // 按 source 分组
        let grouped = Dictionary(grouping: collapsed, by: \.source)
        return SkillSource.allCases.compactMap { src in
            guard let arr = grouped[src], !arr.isEmpty else { return nil }
            return SkillGroup(source: src, entries: arr.sorted { $0.name < $1.name })
        }
    }

    func versions(forName name: String) -> [SkillEntry] {
        entries.filter { $0.name == name }
            .sorted { ($0.version ?? "") > ($1.version ?? "") }
    }

    func scan() async {
        loading = true
        defer { loading = false }
        let scanner = SkillScanner()
        entries = await scanner.scan()
        lastScanDate = Date()
    }

    func refresh() async { await scan() }

    func loadSkillMd(for entry: SkillEntry) -> String {
        if let cached = skillMdCache[entry.id] { return cached }
        let content = (try? String(contentsOfFile: entry.skillMdPath, encoding: .utf8)) ?? ""
        skillMdCache[entry.id] = content
        return content
    }

    private func matchesQuery(_ e: SkillEntry) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        if e.name.lowercased().contains(q) { return true }
        if e.description.lowercased().contains(q) { return true }
        if e.skillDirPath.lowercased().contains(q) { return true }
        return false
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

Run: `swift test --filter AppModelTests`
Expected: PASS（6 个测试）

- [ ] **Step 5: Commit**

```bash
git add Sources/SkillHub/ViewModels/AppModel.swift Tests/SkillHubTests/AppModelTests.swift
git commit -m "feat: add AppModel with filtering and multi-version folding"
```

---

### Task 11: MarkdownRenderer（AttributedString 包装）

**Files:**
- Create: `Sources/SkillHub/Views/MarkdownRenderer.swift`

**Interfaces:**
- Produces: `enum MarkdownRenderer { static func render(_ md: String) -> AttributedString }` —— 用 `AttributedString(markdown:options:)`，失败回退为纯文本 AttributedString（`.monospaced`）。

- [ ] **Step 1: 写实现**

```swift
import Foundation
import SwiftUI

enum MarkdownRenderer {
    static func render(_ md: String) -> AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        do {
            return try AttributedString(markdown: md, options: options)
        } catch {
            return AttributedString(md)
        }
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/SkillHub/Views/MarkdownRenderer.swift
git commit -m "feat: add MarkdownRenderer using AttributedString"
```

---

### Task 12: SidebarView（来源过滤）

**Files:**
- Create: `Sources/SkillHub/Views/SidebarView.swift`

**Interfaces:**
- Consumes: `@Bindable var model: AppModel`
- Produces: `struct SidebarView: View` —— 列出 `SkillSource.allCases`，点击设置 `model.selectedSources` 为单元素集合（点"全部"清空）。高亮当前选中。显示每来源的 skill 数量（基于 `model.entries`）。

- [ ] **Step 1: 写实现**

```swift
import SwiftUI

struct SidebarView: View {
    @Bindable var model: AppModel

    var body: some View {
        List(selection: Binding(
            get: { model.selectedSources.first ?? .personal },
            set: { src in model.selectedSources = [src] }
        )) {
            Section {
                Label("全部", systemImage: "square.grid.2x2")
                    .tag(SkillSource.personal) // 占位 tag；"全部"由工具栏按钮处理
                    .onTapGesture { model.selectedSources = [] }
            }
            Section("来源") {
                ForEach(SkillSource.allCases) { src in
                    HStack {
                        Label(src.displayName, systemImage: src.icon)
                        Spacer()
                        Text("\(count(for: src))")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .tag(src)
                    .onTapGesture { model.selectedSources = [src] }
                }
            }
        }
        .navigationTitle("SkillHub")
    }

    private func count(for source: SkillSource) -> Int {
        model.entries.filter { $0.source == source }.count
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/SkillHub/Views/SidebarView.swift
git commit -m "feat: add SidebarView for source filtering"
```

---

### Task 13: SkillListView + SkillRowView（搜索 + 分组列表）

**Files:**
- Create: `Sources/SkillHub/Views/SkillListView.swift`
- Create: `Sources/SkillHub/Views/SkillRowView.swift`

**Interfaces:**
- Consumes: `@Bindable var model: AppModel`
- Produces: `struct SkillListView: View` —— 顶部搜索框（绑定 `model.query`），下方按 `model.filteredAndGrouped` 分组展示。每个 name 默认显示最新版本行，带"还有 N 个版本"按钮，点击把 name 加入 `expandedNames`。
- Produces: `struct SkillRowView: View` —— 单行显示 name、description 摘要、版本号、来源图标。

- [ ] **Step 1: 写 `SkillRowView`**

```swift
import SwiftUI

struct SkillRowView: View {
    let entry: SkillEntry
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.name).font(.body).bold()
                if let v = entry.version {
                    Text(v)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(.quaternary, in: .capsule)
                }
            }
            if !entry.description.isEmpty {
                Text(entry.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}
```

- [ ] **Step 2: 写 `SkillListView`**

```swift
import SwiftUI

struct SkillListView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("搜索 skill…", text: $model.query)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.bar)
            Divider()
            List(selection: $model.selectedEntryID) {
                ForEach(model.filteredAndGrouped) { group in
                    Section(group.source.displayName) {
                        ForEach(group.entries) { entry in
                            SkillRowView(entry: entry, isSelected: entry.id == model.selectedEntryID)
                                .tag(entry.id)
                            if !model.expandedNames.contains(entry.name) {
                                let others = model.versions(forName: entry.name)
                                if others.count > 1 {
                                    Button("还有 \(others.count - 1) 个版本") {
                                        model.expandedNames.insert(entry.name)
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Skills")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await model.refresh() }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}
```

- [ ] **Step 3: 构建验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Sources/SkillHub/Views/SkillListView.swift Sources/SkillHub/Views/SkillRowView.swift
git commit -m "feat: add SkillListView with search and grouping"
```

---

### Task 14: MetaInfoCard（元信息卡片）

**Files:**
- Create: `Sources/SkillHub/Views/MetaInfoCard.swift`

**Interfaces:**
- Consumes: `let entry: SkillEntry`
- Produces: `struct MetaInfoCard: View` —— 展示 name、description、来源、版本、路径、大小、文件数。按钮："在 Finder 中显示"（`NSWorkspace.shared.openFile` 父目录）、"复制路径"（写入 `NSPasteboard`）。

- [ ] **Step 1: 写实现**

```swift
import SwiftUI
import AppKit

struct MetaInfoCard: View {
    let entry: SkillEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.name).font(.title2).bold()
            if !entry.description.isEmpty {
                Text(entry.description).foregroundStyle(.secondary)
            }
            Divider()
            LabeledContent("来源", value: entry.source.displayName)
            LabeledContent("版本", value: entry.version ?? "—")
            LabeledContent("大小", value: formatBytes(entry.sizeBytes))
            LabeledContent("文件数", value: "\(entry.fileCount)")
            LabeledContent("路径", value: entry.skillDirPath)
                .font(.caption).monospaced()
            HStack {
                Button("在 Finder 中显示") {
                    NSWorkspace.shared.openFile(entry.skillDirPath, withApplication: "Finder")
                }
                Button("复制路径") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(entry.skillDirPath, forType: .string)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.regularMaterial, in: .roundedRectangle(cornerRadius: 8))
    }

    private func formatBytes(_ b: Int) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var v = Double(b)
        var i = 0
        while v >= 1024, i < units.count - 1 { v /= 1024; i += 1 }
        return String(format: "%.1f %@", v, units[i])
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/SkillHub/Views/MetaInfoCard.swift
git commit -m "feat: add MetaInfoCard"
```

---

### Task 15: FileTreeView（目录文件浏览）

**Files:**
- Create: `Sources/SkillHub/Views/FileTreeView.swift`

**Interfaces:**
- Consumes: `let skillDirPath: String`
- Produces: `struct FileTreeView: View` —— 递归列出 skill 目录文件，脚本文件（`ScriptLanguage` 支持）点击触发 `onRunScript: (ScriptFile) -> Void` 回调，其他文件点击在右内侧栏预览文本（`.monospaced`）。

- [ ] **Step 1: 写实现**

```swift
import SwiftUI

struct FileTreeView: View {
    let skillDirPath: String
    let onRunScript: (ScriptFile) -> Void
    @State private var files: [ScriptFile] = []
    @State private var previewFile: ScriptFile?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("文件").font(.headline)
            List(files, id: \.id) { f in
                HStack {
                    Image(systemName: iconFor(f))
                    Text(f.relativePath).monospaced()
                    Spacer()
                    if f.language.interpreter != nil {
                        Button("运行") { onRunScript(f) }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { previewFile = f }
            }
            if let pv = previewFile {
                ScrollView {
                    Text(pv.contentPreview)
                        .font(.caption).monospaced()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 160)
                .background(.quaternary)
            }
        }
        .task { loadFiles() }
    }

    private func iconFor(_ f: ScriptFile) -> String {
        switch f.language {
        case .shell:  return "terminal"
        case .python: return "chevron.left.forwardslash.chevron.right"
        case .node:   return "curlybraces"
        case .other:  return "doc"
        }
    }

    private func loadFiles() {
        var collected: [ScriptFile] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: skillDirPath) else { return }
        while let item = enumerator.nextObject() as? String {
            let full = skillDirPath + "/" + item
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: full, isDirectory: &isDir), !isDir.boolValue else { continue }
            if let sf = try? ScriptFile.make(at: full, skillDirPath: skillDirPath) {
                collected.append(sf)
            }
        }
        files = collected.sorted { $0.relativePath < $1.relativePath }
    }
}
```

- [ ] **Step 2: 构建验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/SkillHub/Views/FileTreeView.swift
git commit -m "feat: add FileTreeView"
```

---

### Task 16: ScriptPreviewSheet + ScriptResultView（脚本预览执行）

**Files:**
- Create: `Sources/SkillHub/Views/ScriptPreviewSheet.swift`
- Create: `Sources/SkillHub/Views/ScriptResultView.swift`

**Interfaces:**
- Produces: `struct ScriptPreviewSheet: View` —— 显示脚本路径、大小、语言、前 50 行预览；"执行"按钮调 `ScriptRunner.run(script:)`，结果存 `@State`，下方展示 `ScriptResultView`。
- Produces: `struct ScriptResultView: View` —— 展示 stdout、stderr、exitCode、timedOut、truncated。

- [ ] **Step 1: 写 `ScriptResultView`**

```swift
import SwiftUI

struct ScriptResultView: View {
    let result: ScriptResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("退出码：\(result.exitCode)\(result.timedOut ? "（超时）" : "")\(result.truncated ? "（输出已截断）" : "")")
                .font(.caption).foregroundStyle(.secondary)
            if !result.stdout.isEmpty {
                Text("stdout").font(.caption).bold()
                ScrollView { Text(result.stdout).font(.caption).monospaced().frame(maxWidth: .infinity, alignment: .leading) }
                    .frame(height: 120).background(.quaternary)
            }
            if !result.stderr.isEmpty {
                Text("stderr").font(.caption).bold()
                ScrollView { Text(result.stderr).font(.caption).monospaced().frame(maxWidth: .infinity, alignment: .leading) }
                    .frame(height: 80).background(.quaternary)
            }
        }
    }
}
```

- [ ] **Step 2: 写 `ScriptPreviewSheet`**

```swift
import SwiftUI

struct ScriptPreviewSheet: View {
    let script: ScriptFile
    @State private var result: ScriptResult?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("预览脚本").font(.headline)
            LabeledContent("路径", value: script.id).font(.caption).monospaced()
            LabeledContent("大小", value: "\(script.sizeBytes) 字节")
            LabeledContent("语言", value: script.language.rawValue)
            Text("预览（前 50 行）").font(.caption).bold()
            ScrollView {
                Text(script.contentPreview).font(.caption).monospaced()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 160).background(.quaternary)

            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Button("执行") {
                    result = ScriptRunner.run(script: script)
                }
                .buttonStyle(.borderedProminent)
            }

            if let r = result {
                Divider()
                ScriptResultView(result: r)
            }
        }
        .padding()
        .frame(width: 560, height: 520)
    }
}
```

- [ ] **Step 3: 构建验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Sources/SkillHub/Views/ScriptPreviewSheet.swift Sources/SkillHub/Views/ScriptResultView.swift
git commit -m "feat: add ScriptPreviewSheet and ScriptResultView"
```

---

### Task 17: SkillDetailView（详情页组装）

**Files:**
- Create: `Sources/SkillHub/Views/SkillDetailView.swift`

**Interfaces:**
- Consumes: `let entry: SkillEntry`、`@Bindable var model: AppModel`
- Produces: `struct SkillDetailView: View` —— `ScrollView` 内：`MetaInfoCard` + SKILL.md Markdown（`MarkdownRenderer.render(model.loadSkillMd(for: entry))`）+ `FileTreeView`（`onRunScript` 设置 `@State var scriptToRun` 触发 `.sheet`）。

- [ ] **Step 1: 写实现**

```swift
import SwiftUI

struct SkillDetailView: View {
    let entry: SkillEntry
    @Bindable var model: AppModel
    @State private var scriptToRun: ScriptFile?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MetaInfoCard(entry: entry)
                Text("SKILL.md").font(.headline)
                Text(MarkdownRenderer.render(model.loadSkillMd(for: entry)))
                    .textSelection(.enabled)
                FileTreeView(skillDirPath: entry.skillDirPath) { sf in
                    scriptToRun = sf
                }
            }
            .padding()
        }
        .navigationTitle(entry.name)
        .sheet(item: $scriptToRun) { sf in
            ScriptPreviewSheet(script: sf)
        }
    }
}

extension ScriptFile: @retroactive Identifiable {}
```

- [ ] **Step 2: 构建验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/SkillHub/Views/SkillDetailView.swift
git commit -m "feat: add SkillDetailView"
```

---

### Task 18: ContentView（三栏容器）+ App 装配

**Files:**
- Modify: `Sources/SkillHub/SkillHubApp.swift`
- Create: `Sources/SkillHub/Views/ContentView.swift`

**Interfaces:**
- Produces: `struct ContentView: View` —— `NavigationSplitView { SidebarView } content { SkillListView } detail { SkillDetailView 或占位 }`。`@State private var model = AppModel()`，`.task { await model.scan() }`。
- Produces: `SkillHubApp` 注入 `ContentView`。

- [ ] **Step 1: 写 `ContentView`**

```swift
import SwiftUI

struct ContentView: View {
    @State private var model = AppModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(model: model)
        } content: {
            SkillListView(model: model)
        } detail: {
            if let id = model.selectedEntryID,
               let entry = model.entries.first(where: { $0.id == id }) {
                SkillDetailView(entry: entry, model: model)
            } else {
                ContentUnavailableView("选择一个 skill", systemImage: "square.stack.3d.up",
                                       description: Text("从列表中选一个 skill 查看详情"))
            }
        }
        .task {
            if model.entries.isEmpty { await model.scan() }
        }
    }
}
```

- [ ] **Step 2: 改 `SkillHubApp.swift`**

```swift
import SwiftUI

@main
struct SkillHubApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```
（删除骨架 `ContentView` 定义，改由 `Views/ContentView.swift` 提供。）

- [ ] **Step 3: 构建并运行验证**

Run: `swift build`
Expected: BUILD SUCCEEDED

Run: `swift run SkillHub`
Expected: 窗口弹出，三栏布局，列表至少有 8 个个人 skill，点开可见 Markdown 详情。

- [ ] **Step 4: Commit**

```bash
git add Sources/SkillHub/Views/ContentView.swift Sources/SkillHub/SkillHubApp.swift
git commit -m "feat: assemble three-column ContentView and wire app"
```

---

### Task 19: 全量测试 + README

**Files:**
- Create: `README.md`

**Interfaces:**
- Produces: `swift test` 全绿；README 说明构建/运行/测试命令。

- [ ] **Step 1: 跑全量测试**

Run: `swift test`
Expected: 全部 PASS（预期 ~20 个测试）。如有失败，修复后重跑。

- [ ] **Step 2: 写 `README.md`**

```markdown
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
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add README and verify full test suite"
```

---

## Self-Review 结果

**1. Spec 覆盖**：
- 三栏布局 → Task 18
- skill 扫描+多版本 → Task 7+8
- 元信息 + Markdown → Task 11+14+17
- 目录文件浏览 → Task 15
- 脚本预览+执行 → Task 9+16
- 来源过滤 / 搜索 / 多版本折叠 → Task 10+12+13
- 启动扫描+手动刷新 → Task 18（`.task`）+ Task 13（刷新按钮）
- Finder/复制路径 → Task 14
- 错误处理（扫描失败回退、front matter 损坏、无权限兜底、超时、截断）→ Task 6+8+9
- 测试（单元 + fixtures + UI 手动）→ 各 Task + Task 19
- 设计决策表逐条对应 Global Constraints 与各 Task

**2. 占位符扫描**：无 TBD/TODO/"add error handling" 等模式；每步含具体代码或命令。

**3. 类型一致性**：`SkillEntry.id`/`skillMdPath`/`skillDirPath`、`AppModel.loadSkillMd(for:)`、`ScriptRunner.run(script:)`、`ScriptFile.make(at:skillDirPath:)`、`PathProvider.classify(marketplace:plugin:)` 在各 Task 间签名一致；`SkillSource` rawValue 与 `classify` 用例字符串对齐（`personal`/`superpowers`/`frontend_design`/`ponytail`/`glm_plan_usage`/`other`）。

**执行选项见下。**

