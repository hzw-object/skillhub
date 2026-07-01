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
