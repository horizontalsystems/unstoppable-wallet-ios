import SwiftUI

struct ThemeText: View {
    private let text: TextType
    private let style: TextStyle
    private let colorStyle: ColorStyle
    private let dimmed: Bool

    init(_ text: CustomStringConvertible, style: TextStyle, colorStyle: ColorStyle? = nil, dimmed: Bool = false) {
        if let componentText = text as? ComponentText {
            self.text = .plain(componentText.text)
            self.style = style
            self.colorStyle = colorStyle ?? componentText.colorStyle ?? style.defaultColorStyle
            self.dimmed = dimmed || componentText.dimmed
        } else {
            self.text = .plain(text.description)
            self.style = style
            self.colorStyle = colorStyle ?? style.defaultColorStyle
            self.dimmed = dimmed
        }
    }

    init(_ attributedString: AttributedString, style: TextStyle, colorStyle: ColorStyle? = nil, dimmed: Bool = false) {
        text = .attributed(attributedString)
        self.style = style
        self.colorStyle = colorStyle ?? style.defaultColorStyle
        self.dimmed = dimmed
    }

    var body: some View {
        Group {
            switch text {
            case let .plain(text): Text(text)
            case let .attributed(text): Text(text)
            }
        }
        .font(style.font)
        .foregroundColor(colorStyle.color(dimmed: dimmed))
    }
}

extension ThemeText {
    enum TextType: Equatable {
        case plain(String)
        case attributed(AttributedString)
    }
}
