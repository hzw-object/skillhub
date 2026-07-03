import SwiftUI
import MarkdownUI
import Highlightr
#if os(macOS)
import AppKit
#endif

/// 基于 [Highlightr](https://github.com/raspu/Highlightr) 的代码块语法高亮。
///
/// `MarkdownUI` 默认用 `PlainTextCodeSyntaxHighlighter`，围栏代码块无配色。
/// 本实现把 `highlight(_:as:)` 返回的 `NSAttributedString` 翻译成 SwiftUI `Text`：
/// 按属性 run 分段，逐段应用前景色 / 字重 / 斜体，再用 `+` 拼成一段高亮文本。
///
/// 主题跟随系统外观：浅色用 `atom-one-light`，深色用 `atom-one-dark`。
struct HighlightrCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let highlightr: Highlightr?

    init() {
        // Highlightr 内部用 JSContext + highlight.min.js，初始化有开销但可复用。
        // 实例化失败（极罕见，仅 highlight.min.js 缺失）时回退到纯文本，不致整页崩。
        if let h = Highlightr() {
            _ = h.setTheme(to: Self.themeName(forDarkMode: Self.isDarkMode))
            self.highlightr = h
        } else {
            self.highlightr = nil
        }
    }

    func highlightCode(_ code: String, language: String?) -> Text {
        guard let highlightr else { return Text(code) }
        // MarkdownUI 对无 fence 语言的块可能传空串；统一成 nil 走 auto-detect。
        let lang = (language?.isEmpty == false) ? language : nil
        let attr = highlightr.highlight(code, as: lang, fastRender: true)
            ?? NSAttributedString(string: code)
        return Self.text(from: attr)
    }

    /// 由 `NSAttributedString` 构造 SwiftUI `Text`：按属性 run 分段拼接。
    static func text(from attr: NSAttributedString) -> Text {
        let base = attr.string
        var result: Text?
        let full = NSRange(location: 0, length: attr.length)
        attr.enumerateAttributes(in: full, options: []) { attrs, range, _ in
            let segment = (base as NSString).substring(with: range)
            var seg = Text(segment)
            #if os(macOS)
            if let color = attrs[.foregroundColor] as? NSColor {
                let srgb = color.usingColorSpace(.sRGB) ?? color
                seg = seg.foregroundColor(Color(srgb))
            }
            if let font = attrs[.font] as? NSFont {
                // Highlightr 的 font-style/font-weight 都映射到 .font：
                //   bold/bolder/600+  → boldCodeFont
                //   italic/oblique     → italicCodeFont
                //   其余              → codeFont
                // 通过 fontName 后缀判断属于哪一类（Highlightr 自带主题里这三种字体
                // 分别由不同 descriptor 派生，名字带 Bold/Italic 或两者皆无）。
                let name = font.fontName.lowercased()
                if name.contains("italic") {
                    seg = seg.italic()
                }
                if name.contains("bold") {
                    seg = seg.bold()
                }
            }
            #endif
            result = result == nil ? seg : result! + seg
        }
        return result ?? Text(base)
    }

    // MARK: - 外观与主题

    /// 当前是否深色模式。非主线程或拿不到 appearance 时按浅色处理。
    static var isDarkMode: Bool {
        #if os(macOS)
        guard Thread.isMainThread else { return false }
        return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .vibrantDark]) == .darkAqua
        #else
        return false
        #endif
    }

    private static func themeName(forDarkMode dark: Bool) -> String {
        dark ? "atom-one-dark" : "atom-one-light"
    }
}
