import SwiftUI

struct ThemeText: View {
    private let text: TextType
    private let style: TextStyle
    private let color: Color

    init(_ text: CustomStringConvertible, style: TextStyle, color: Color? = nil) {
        if let componentText = text as? ComponentText {
            self.text = .plain(componentText.text)
            self.style = style
            self.color = componentText.color ?? color ?? .themeLeah
        } else if let componentText = text as? AttributedComponentText {
            self.text = .attributed(componentText.text)
            self.style = style
            self.color = color ?? .themeLeah
        } else {
            self.text = .plain(text.description)
            self.style = style
            self.color = color ?? .themeLeah
        }
    }

    init(_ attributedString: AttributedString, style: TextStyle, color: Color? = nil) {
        text = .attributed(attributedString)
        self.style = style
        self.color = color ?? .themeLeah
    }

    init(key: LocalizedStringResource, style: TextStyle, color: Color? = nil) {
        text = .localized(key)
        self.style = style
        self.color = color ?? .themeLeah
    }

    init(_ text: TextType, style: TextStyle, color: Color? = nil) {
        self.text = text
        self.style = style
        self.color = color ?? .themeLeah
    }

    var body: some View {
        Group {
            switch text {
            case let .localized(key): Text(key)
            case let .plain(text): Text(text)
            case let .attributed(text): Text(text)
            }
        }
        .font(style.font)
        .foregroundColor(color)
    }
}

extension ThemeText {
    enum TextType: Equatable {
        case localized(LocalizedStringResource)
        case plain(String)
        case attributed(AttributedString)
    }
}
