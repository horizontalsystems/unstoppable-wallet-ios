import SwiftUI

struct DefenseSystemView: View {
    let placement: Placement
    let style: Style
    var icon: String?
    var title: String?
    var text: String?
    var action: (String, () -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            switch placement {
            case .top:
                defenseSystem()
                bubble(tailPosition: .top)
            case .bottom:
                bubble(tailPosition: .bottom)
                defenseSystem()
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder private func defenseSystem() -> some View {
        HStack(spacing: 8) {
            ThemeImage(ComponentImage(image: "defense_filled"), size: 20)
            ThemeText("Defense System", style: .subhead, colorStyle: .primary)
            Spacer()
        }
    }

    @ViewBuilder private func bubble(tailPosition: BubbleShape.TailPosition) -> some View {
        BubbleView(
            tailPosition: tailPosition,
            strokeColor: style.strokeColor,
            fillColor: style.fillColor,
        ) {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    if let title {
                        HStack(spacing: 8) {
                            if let icon {
                                ThemeImage(icon, size: 20, colorStyle: style.titleColorStyle)
                            }
                            ThemeText(title, style: .headline2, colorStyle: style.titleColorStyle)
                            Spacer()
                        }
                    }

                    if let text {
                        ThemeText(text, style: .subheadR, colorStyle: style.textColorStyle)
                    }
                }
                if let action {
                    HStack(spacing: 0) {
                        Spacer()

                        Button(action: action.1) {
                            HStack(spacing: 8) {
                                ThemeText(action.0, style: .subheadSB, colorStyle: style.textColorStyle)
                                ThemeImage("arrow_m_right", size: 20, colorStyle: style.textColorStyle)
                            }
                        }
                    }
                }
            }
        }
    }

    enum Placement {
        case top
        case bottom
    }

    enum Style {
        case loading
        case notAvailable
        case positive
        case attention
        case negative

        var strokeColor: Color? {
            switch self {
            case .loading: return .themeAndy
            case .notAvailable: return .themeGray
            case .positive: return .themeRemus
            case .attention: return nil
            case .negative: return .themeLucian
            }
        }

        var fillColor: Color? {
            switch self {
            case .attention: return .themeYellow
            default: return nil
            }
        }

        var titleColorStyle: ColorStyle {
            switch self {
            case .loading: return .secondary
            case .notAvailable: return .primary
            case .positive: return .green
            case .attention: return .dark
            case .negative: return .red
            }
        }

        var textColorStyle: ColorStyle {
            switch self {
            case .loading, .notAvailable: return .secondary
            case .positive, .negative: return .primary
            case .attention: return .dark
            }
        }
    }
}
