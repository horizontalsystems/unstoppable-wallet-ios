import SwiftUI
import UIKit

enum MarkdownAttributedStringConverter {
    static let linkColor: UIColor = .themeJacob

    static func attributedString(from nsAttributedString: NSAttributedString) -> AttributedString {
        let source = normalizedLinks(nsAttributedString)

        // Conversion only throws on attribute values of unexpected types; `.link` (the one Down emits as String) is normalized to URL above, so this fallback is effectively unreachable
        guard var result = try? AttributedString(source, including: \.uiKit) else {
            return AttributedString(nsAttributedString.string)
        }

        for run in result.runs {
            let range = run.range
            let font = run.uiKit.font
            let foregroundColor = run.uiKit.foregroundColor
            let underlineStyle = run.uiKit.underlineStyle
            let strikethroughStyle = run.uiKit.strikethroughStyle
            let isLink = run.link != nil

            var container = AttributeContainer()

            if let font {
                container.swiftUI.font = Font(font as CTFont)
            }

            if isLink {
                container.swiftUI.foregroundColor = Color(uiColor: linkColor)
                container.swiftUI.underlineStyle = .single
            } else {
                if let foregroundColor {
                    container.swiftUI.foregroundColor = Color(uiColor: foregroundColor)
                }

                if let underlineStyle, underlineStyle != [] {
                    container.swiftUI.underlineStyle = Text.LineStyle(nsUnderlineStyle: underlineStyle)
                }
            }

            if let strikethroughStyle, strikethroughStyle != [] {
                container.swiftUI.strikethroughStyle = Text.LineStyle(nsUnderlineStyle: strikethroughStyle)
            }

            result[range].uiKit.font = nil
            result[range].uiKit.foregroundColor = nil
            result[range].uiKit.paragraphStyle = nil
            result[range].uiKit.underlineStyle = nil
            result[range].uiKit.underlineColor = nil
            result[range].uiKit.strikethroughStyle = nil
            result[range].uiKit.strikethroughColor = nil
            result[range].mergeAttributes(container)
        }

        return result
    }

    static func attributedString(string: String, font: UIFont, color: UIColor) -> AttributedString {
        var result = AttributedString(string)
        result.swiftUI.font = Font(font as CTFont)
        result.swiftUI.foregroundColor = Color(uiColor: color)
        return result
    }

    // Down stores `.link` as a String; Foundation's `AttributedString` link attribute expects a URL
    private static func normalizedLinks(_ nsAttributedString: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: nsAttributedString)
        let fullRange = NSRange(location: 0, length: mutable.length)

        mutable.enumerateAttribute(.link, in: fullRange) { value, range, _ in
            guard let string = value as? String else {
                return
            }

            if let url = URL(string: string) {
                mutable.addAttribute(.link, value: url, range: range)
            } else {
                mutable.removeAttribute(.link, range: range)
            }
        }

        return mutable
    }
}
