import SwiftUI
import MarkdownUI

/// SKILL.md 块级渲染主题。
///
/// `MarkdownUI` 默认主题在大字体 + 默认字距下标题/段落间距偏紧、代码块灰底边界不清。
/// 本主题基于 `.gitHub` 并按「长文档阅读体验」微调：段落行距、代码块圆角、引用块左侧色条。
extension Theme {
    /// SkillHub 专用 Markdown 阅读主题。
    static let skill = Theme()
        .text {
            FontSize(15)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.88))
            BackgroundColor(Color(nsColor: .textBackgroundColor).opacity(0.8))
        }
        .strong {
            FontWeight(.semibold)
        }
        .heading1 { configuration in
            VStack(alignment: .leading, spacing: 6) {
                configuration.label
                    .markdownTextStyle {
                        FontSize(26)
                        FontWeight(.semibold)
                    }
                Divider()
            }
            .markdownMargin(top: 24, bottom: 14)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(21)
                    FontWeight(.semibold)
                }
                .markdownMargin(top: 22, bottom: 8)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(17)
                    FontWeight(.semibold)
                }
                .markdownMargin(top: 16, bottom: 6)
        }
        .heading4 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(15)
                    FontWeight(.semibold)
                }
                .markdownMargin(top: 12, bottom: 4)
        }
        .heading5 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(14)
                    FontWeight(.semibold)
                }
                .markdownMargin(top: 10, bottom: 4)
        }
        .heading6 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(13)
                    FontWeight(.semibold)
                    ForegroundColor(.secondary)
                }
                .markdownMargin(top: 10, bottom: 4)
        }
        .paragraph { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.18))
                .markdownMargin(top: 0, bottom: 12)
        }
        .blockquote { configuration in
            configuration.label
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.accentColor.opacity(0.55))
                        .frame(width: 3)
                        .padding(.vertical, 2)
                }
                .markdownMargin(top: 0, bottom: 12)
        }
        .codeBlock { configuration in
            VStack(alignment: .leading, spacing: 0) {
                // 语言标签条：左上角显示 fence 语言，无语言则隐藏，统一与下方代码块的圆角
                if let language = configuration.language, !language.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.slash.chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                        Text(language.uppercased())
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Color(nsColor: .textBackgroundColor).opacity(0.55)
                    )
                }
                // 代码区：横向滚动 + 等宽字体，左边缘补一条强调色竖条作为视觉锚点
                ScrollView(.horizontal, showsIndicators: false) {
                    configuration.label
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(13)
                        }
                        .textSelection(.enabled)
                        .padding(.vertical, 2)
                }
                .padding(.leading, 14)
                .padding(.trailing, 14)
                .padding(.top, 12)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color(nsColor: .textBackgroundColor).opacity(0.85)
                )
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.accentColor.opacity(0.5))
                        .frame(width: 3)
                        .padding(.vertical, 10)
                }
            }
            .background(
                Color(nsColor: .textBackgroundColor).opacity(0.85)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.75)
            )
            .markdownMargin(top: 4, bottom: 14)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: 2, bottom: 2)
        }
        .table { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                // 表头深底 + 正文隔行浅底：区别 GitHub 主题的纯色填充，
                // 用半透明材质让表格在浅/深色窗口下都贴合窗口背景。
                .markdownTableBackgroundStyle(.alternatingRows(
                    Color(nsColor: .textBackgroundColor).opacity(0.45),
                    Color.clear,
                    header: Color.accentColor.opacity(0.12)
                ))
                // 仅保留横向分隔线（表头下 + 行间），去掉竖线，视觉更轻盈。
                .markdownTableBorderStyle(.init(
                    .horizontalBorders,
                    color: Color(nsColor: .separatorColor).opacity(0.6),
                    width: 0.75
                ))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.75)
                )
                .markdownMargin(top: 0, bottom: 12)
        }
        .tableCell { configuration in
            configuration.label
                .markdownTextStyle {
                    if configuration.row == 0 {
                        FontWeight(.semibold)
                    }
                    BackgroundColor(nil)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .relativeLineSpacing(.em(0.2))
        }
        .thematicBreak {
            Divider()
                .markdownMargin(top: 12, bottom: 12)
        }
}
