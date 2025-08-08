import SwiftUI

struct ThemeText: View {
    private let text: String
    private let style: TextStyle
    private let colorStyle: TextColorStyle
    private let dimmed: Bool

    init(_ text: CustomStringConvertible, style: TextStyle, colorStyle: TextColorStyle? = nil, dimmed: Bool = false) {
        if let componentText = text as? ComponentText {
            self.text = componentText.text
            self.style = style
            self.colorStyle = colorStyle ?? componentText.colorStyle ?? style.defaultColorStyle
            self.dimmed = dimmed || componentText.dimmed
        } else {
            self.text = text.description
            self.style = style
            self.colorStyle = colorStyle ?? style.defaultColorStyle
            self.dimmed = dimmed
        }
    }

    var body: some View {
        Text(text)
            .font(style.font)
            .foregroundColor(colorStyle.color(dimmed: dimmed))
    }
}
