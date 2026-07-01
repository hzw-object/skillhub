# SkillHub — Mac Skill 客户端设计

**日期**：2026-07-01
**状态**：已通过 brainstorming，待 writing-plans
**技术栈**：原生 SwiftUI，macOS 13+

## 1. 概述

SkillHub 是一个原生 macOS 应用，用于浏览和查看本机所有 Claude Code skill。它能读取所有 skill 存放位置（个人 skills + 各 plugin cache），保留同一 skill 的多个版本，并提供元信息、Markdown 渲染、目录文件浏览、脚本预览执行等详情能力。

### 功能范围

- 扫描本机所有 skill 存放位置，保留多版本
- 三栏布局：来源过滤侧边栏 / 搜索+分组列表 / 详情视图
- 详情页：元信息卡片 + SKILL.md Markdown 渲染 + skill 目录文件浏览
- 附加能力：在 Finder 中显示、复制路径、执行脚本（带预览确认）
- 启动扫描 + 手动刷新

### 非目标

- 不做 skill 的编辑/创建/删除
- 不做网络请求
- 不做 skill 的导入导出
- 不做性能基准测试
- 不持久化缓存（每次启动重新扫描）

## 2. 架构

### 2.1 整体形态

单窗口 `NavigationSplitView` 三栏：

```
┌─────────────┬────────────────────┬──────────────────────────┐
│  侧边栏      │   skill 列表        │   详情视图                │
│ (来源过滤)   │ (搜索 + 分组列表)   │ (元信息 + Markdown + 文件)│
└─────────────┴────────────────────┴──────────────────────────┘
```

### 2.2 工程结构

```
SkillHub/
├── SkillHubApp.swift            # App 入口，注入 AppModel
├── Models/
│   ├── SkillSource.swift         # 来源枚举
│   ├── SkillEntry.swift          # skill 数据模型
│   └── ScriptFile.swift          # 脚本模型
├── Services/
│   ├── SkillScanner.swift        # 扫描器
│   ├── SkillMarkdownParser.swift # YAML front matter 解析
│   ├── ScriptRunner.swift        # 脚本执行
│   └── PathProvider.swift        # skill 根目录定位
├── ViewModels/
│   └── AppModel.swift            # @Observable 全局状态
├── Views/
│   ├── ContentView.swift         # 三栏容器
│   ├── SidebarView.swift         # 来源过滤
│   ├── SkillListView.swift       # 搜索框 + 分组列表
│   ├── SkillRowView.swift        # 单行
│   ├── SkillDetailView.swift    # 详情
│   ├── MetaInfoCard.swift        # 元信息卡片
│   ├── MarkdownRenderer.swift    # Down 包装
│   ├── FileTreeView.swift        # skill 目录文件列表
│   ├── ScriptPreviewSheet.swift  # 执行前预览+确认
│   └── ScriptResultView.swift    # 执行结果输出
└── Resources/
```

### 2.3 依赖

仅 `Down`（Markdown → AttributedString），通过 SPM 引入。

## 3. 数据模型

### 3.1 SkillSource

```swift
enum SkillSource: String, CaseIterable, Identifiable, Hashable {
    case personal            // ~/.claude/skills/
    case superpowers        // superpowers-marketplace + claude-plugins-official 下的 superpowers
    case frontendDesign     // claude-plugins-official/frontend-design
    case ponytail           // ponytail/ponytail + ponytail/.openclaw
    case glmPlanUsage       // zai-coding-plugins/glm-plan-usage
    case other              // 兜底
    var id: String { rawValue }
    var displayName: String { ... }   // "个人 Skills"、"Superpowers" 等
    var icon: String { ... }          // SF Symbols
}
```

### 3.2 SkillEntry

```swift
struct SkillEntry: Identifiable, Hashable {
    let id: String             // 绝对路径，天然唯一且区分多版本
    let name: String          // front matter 的 name，无则用目录名
    let description: String   // front matter 的 description
    let source: SkillSource
    let skillDirPath: String  // skill 目录绝对路径
    let skillMdPath: String   // SKILL.md 绝对路径
    let version: String?      // 路径中的版本号（如 "6.1.0"），无则 nil
    let sizeBytes: Int        // skill 目录总大小
    let fileCount: Int        // skill 目录下文件总数
    let skillMdContent: String  // 列表阶段不填，详情页按需读取
}
```

### 3.3 ScriptFile

```swift
enum ScriptLanguage { case shell, python, node, other }

struct ScriptFile: Identifiable, Hashable {
    let id: String             // 绝对路径
    let name: String           // 文件名
    let relativePath: String  // 相对 skill 目录的路径
    let sizeBytes: Int
    let language: ScriptLanguage  // 按扩展名判断
    let contentPreview: String    // 前 50 行
}
```

## 4. 服务

### 4.1 PathProvider

返回所有 skill 根目录。匹配规则：在 `~/.claude/plugins/cache/` 下，按 `<marketplace>/<plugin>/<version>/skills` 三层结构扫描各 marketplace，取所有含 `skills` 子目录的 `<marketplace>/<plugin>/<version>/` 路径下的 `skills`。来源归属按 marketplace+plugin 名判定：

- `personal`：`~/.claude/skills/`（固定）
- `superpowers`：marketplace ∈ {`superpowers-marketplace`, `claude-plugins-official`} 且 plugin = `superpowers`
- `frontendDesign`：marketplace = `claude-plugins-official` 且 plugin = `frontend-design`
- `ponytail`：marketplace = `ponytail` 且 plugin = `ponytail`（含其下 `.openclaw/skills` 子目录，作 `ponytail` 同一来源）
- `glmPlanUsage`：marketplace = `zai-coding-plugins` 且 plugin = `glm-plan-usage`
- `other`：以上均不匹配时的兜底

`~` 用 `NSHomeDirectory()` 展开，失败回退 `FileManager.default.currentDirectoryPath`。

### 4.2 SkillScanner

- 枚举所有根目录，对每个含 `SKILL.md` 的子目录构造 `SkillEntry`。
- 多版本保留：同一 `name` 不同路径即不同条目。
- 用 `TaskGroup` 并发扫描各根目录。
- 统计目录大小/文件数，解析 front matter。
- 列表阶段**不**填充 `skillMdContent`。

### 4.3 SkillMarkdownParser

- 手写轻量 YAML front matter 解析（不依赖 Yams）。
- 提取 `name`/`description`。
- 处理多行 `description: |` 块标量。
- 损坏 YAML 不抛异常，回退默认值。

### 4.4 ScriptRunner

- 用 `Process` + `Pipe` 执行。
- 超时 30s。
- 无执行权限时用解释器兜底：`.sh`→`bash`，`.py`→`python3`，`.js`→`node`。
- 增量读取输出，截断到 10000 字符。
- 返回结构化结果（stdout/stderr/exitCode/timedOut）。

## 5. ViewModel

### 5.1 AppModel

```swift
@Observable final class AppModel {
    var entries: [SkillEntry] = []
    var selectedEntryID: String?      // 选中的 skill
    var query: String = ""            // 搜索框
    var selectedSources: Set<SkillSource> = []  // 空集=全部
    var loading: Bool = false
    var expandedNames: Set<String> = []  // 多版本折叠展开状态
    var lastScanDate: Date?
    var scanErrors: [ScanError] = []
    private var skillMdCache: [String: String] = [:]  // 已读 SKILL.md 正文

    var filteredAndGrouped: [SkillGroup] { ... }  // 过滤+搜索+按 source 分组
    func scan() async { ... }
    func refresh() async { ... }
    func loadSkillMd(for entry: SkillEntry) -> String { ... }  // 带缓存
}
```

### 5.2 SkillGroup

```swift
struct SkillGroup: Identifiable {
    let source: SkillSource
    let entries: [SkillEntry]
    var id: String { source.rawValue }
}
```

## 6. 数据流

### 6.1 启动

```
App 启动
  └─ SkillHubApp.task {
       appModel.loading = true
       await appModel.scan()
       appModel.loading = false
     }
       └─ scan() {
            dirs = PathProvider.rootDirectories()
            TaskGroup 并发扫描每个 dir
            每个 dir 递归找含 SKILL.md 的子目录
            每个 skill：统计大小/文件数，读 SKILL.md front matter → SkillEntry
            （不读 SKILL.md 正文）
            entries = 收集结果，按 (source, name, version) 排序
            lastScanDate = Date()
          }
```

### 6.2 交互

- **搜索**：`query` 变化 → `filteredAndGrouped` 重算，匹配 `name`/`description`/`skillDirPath`（不区分大小写）。
- **来源过滤**：侧边栏点来源 → `selectedSources = {该来源}`；点"全部" → 空集。
- **选中 skill**：列表点 → `selectedEntryID = id` → 详情页 `.task` 读 SKILL.md 正文 + 扫文件列表。
- **多版本展开**：同 `name` 多版本默认折叠，显示最新版本+"还有 N 个版本"；展开后显示全部。状态存 `expandedNames`。
- **手动刷新**：工具栏刷新按钮 → `refresh()` → 重新 `scan()`。
- **Finder / 复制路径**：元信息卡片按钮，用 `NSWorkspace.open`（父目录）、`NSPasteboard`。
- **执行脚本**：文件列表点脚本 → `ScriptPreviewSheet`（路径/大小/前 50 行）→ 点"执行" → `ScriptRunner` → `ScriptResultView`。

### 6.3 SKILL.md 按需加载

`skillMdContent` 列表阶段不填。详情页打开时 `loadSkillMd(for:)` 读取并缓存到 `skillMdCache`，避免一次读 80+ 文件拖慢启动。

## 7. 错误处理

### 7.1 扫描阶段

- 单根目录扫描失败：捕获异常记到 `scanErrors`，不中断其他根目录。侧边栏对应来源显红感叹号，hover 显示原因。
- SKILL.md 读取/解析失败：`name` 回退目录名，`description` 空字符串，不中断整批。
- 目录大小/文件数统计失败：`sizeBytes = 0`、`fileCount = 0`，详情页显示"未知"。

### 7.2 详情页

- SKILL.md 不存在/不可读：占位"无法读取 SKILL.md"，元信息卡片仍展示已有字段。
- Markdown 渲染失败：回退纯文本（`.monospaced`）。
- 文件列表扫描失败：文件浏览区显示"无法读取目录"。

### 7.3 脚本执行

- 无执行权限：用解释器兜底执行。
- 超时（>30s）：终止，显示"执行超时（30s）已终止"+ 部分输出。
- 非零退出码：展示 stderr 和退出码，不抛异常。
- 大输出：截断到 10000 字符，提示"输出已截断，共 N 字节"。

### 7.4 全局

- `~` 展开失败：`NSHomeDirectory()` → `currentDirectoryPath` 兜底。
- App 不崩溃：所有 I/O 在 `do-catch` 内，异常只影响局部 UI。

## 8. 测试

### 8.1 单元测试（SkillHubTests）

- `PathProviderTests`：根目录集合稳定，`~` 展开正确，不存在目录不抛异常。
- `SkillMarkdownParserTests`：标准 front matter / 无 front matter / 多行块标量 / 损坏 YAML 各路径正确。
- `SkillScannerTests`：单根单 skill / 多版本保留 / 无 SKILL.md 跳过 / 大小文件数正确。
- `ScriptFileTests`：扩展名→language 映射，`contentPreview` 截断到 50 行。
- `ScriptRunnerTests`：echo 成功 / 非零退出码 / 无权限兜底 / 超时终止 / 大输出截断。
- `AppModelTests`：`filteredAndGrouped` 搜索/来源过滤/多版本折叠。

### 8.2 UI 测试（SkillHubUITests，轻量）

- 三栏可见，列表非空（≥8 个个人 skill）。
- 搜索过滤、点列表项出详情、刷新按钮更新 `lastScanDate`。

### 8.3 测试 fixture

- `Tests/Fixtures/`：构造假 skill 目录（标准 / 无 front matter / 多版本 / 带脚本），不依赖真实 `~/.claude`。

### 8.4 非目标

- 不做性能基准、网络测试、Accessibility 自动化。

## 9. 设计决策记录

| 决策 | 选择 | 理由 |
|---|---|---|
| 技术栈 | 原生 SwiftUI | 性能最佳、原生外观、文件访问简单、包体积小 |
| skill 范围 | 全部，保留多版本 | 用户需查看完整 skill 库含版本历史 |
| 详情渲染 | 元信息 + Markdown | 信息最全，兼顾可读性与元数据 |
| SKILL.md 加载 | 按需读取+缓存 | 避免启动读 80+ 文件卡顿 |
| 多版本展示 | 按 name 折叠展开 | 列表整洁，展开可看全部版本 |
| 刷新策略 | 启动扫描+手动刷新 | skill 不频繁变动，实现简单可靠 |
| 脚本执行 | 预览+手动确认 | 防误触，可见可控 |
| 脚本权限 | 解释器兜底 | 绕过 +x 限制，提升可用性 |
| 多版本 ID | 绝对路径 | 天然唯一且区分版本 |
| 依赖 | 仅 Down | 最小依赖面 |
