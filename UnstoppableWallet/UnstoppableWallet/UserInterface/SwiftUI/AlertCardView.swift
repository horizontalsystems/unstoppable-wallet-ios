import SwiftUI

struct AlertCardView: View {
    static let defaultIcon = "warning_filled"
    private let iconName: String
    private let title: String?
    private let text: ThemeText.TextType
    private let type: CardType
    private let style: Style

    init(_ item: AlertCardViewItem) {
        iconName = item.icon
        title = item.style == .inline ? nil : (item.title ?? item.type.defaultTitle)
        text = item.text
        type = item.type
        style = item.style
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if let title {
                titleView(title: title)
            }

            textView()
        }
        .padding(.vertical, .margin16)
        .padding(.horizontal, .margin24)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous).stroke(type.colorStyle.color, lineWidth: .heightOneDp)
        )
    }

    func titleView(title: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(iconName).icon(size: .iconSize20, colorStyle: type.colorStyle)

            ThemeText(title, style: .headline2, colorStyle: type.colorStyle)
        }
        .padding(.trailing, .margin10)
    }

    func textView() -> some View {
        HStack(alignment: .top, spacing: 8) {
            if style == .inline {
                Image(iconName).icon(size: .iconSize20, colorStyle: type.colorStyle)
            }

            Group {
                switch text {
                case let .plain(text): ThemeText(text, style: .subheadR, colorStyle: .primary)
                case let .attributed(text): ThemeText(text, style: .subheadR, colorStyle: .primary)
                }
            }
            .multilineTextAlignment(style.textAlignment)
            .frame(maxWidth: .infinity, alignment: style.alignment)
        }
    }
}

extension AlertCardView {
    enum CardType: Equatable {
        case critical
        case caution

        var colorStyle: ColorStyle {
            switch self {
            case .caution: return .yellow
            case .critical: return .red
            }
        }

        var defaultTitle: String {
            switch self {
            case .caution: return "alert_card.title.caution".localized
            case .critical: return "alert_card.title.critical".localized
            }
        }
    }

    enum Style: Equatable {
        case inline
        case structured

        var textAlignment: TextAlignment {
            switch self {
            case .inline: return .leading
            case .structured: return .center
            }
        }

        var alignment: Alignment {
            switch self {
            case .inline: return .leading
            case .structured: return .center
            }
        }
    }
}

struct AlertCardViewItem: Equatable {
    let icon: String
    let title: String?
    let text: ThemeText.TextType
    let type: AlertCardView.CardType
    let style: AlertCardView.Style

    init(icon: String = AlertCardView.defaultIcon, title: String? = nil, text: String, type: AlertCardView.CardType = .caution, style: AlertCardView.Style = .structured) {
        self.init(icon: icon, title: title, text: .plain(text), type: type, style: style)
    }

    init(icon: String = AlertCardView.defaultIcon, title: String? = nil, text: AttributedString, type: AlertCardView.CardType = .caution, style: AlertCardView.Style = .structured) {
        self.init(icon: icon, title: title, text: .attributed(text), type: type, style: style)
    }

    init(icon: String = AlertCardView.defaultIcon, title: String? = nil, text: ThemeText.TextType, type: AlertCardView.CardType = .caution, style: AlertCardView.Style = .structured) {
        self.icon = icon
        self.title = title
        self.text = text
        self.type = type
        self.style = style
    }
}
