import SwiftUI

struct BadgeViewNew: View {
    private let style: Style
    private let text: String
    private let change: Int?

    init(style: Style = .small, text: String, change: Int? = nil) {
        self.style = style
        self.text = text
        self.change = change
    }

    var body: some View {
        HStack(spacing: .margin2) {
            Text(text.uppercased())
                .font(style.font)
                .foregroundColor(style.foregroundColor)

            if let change, change != 0 {
                if change > 0 {
                    Text(verbatim: "↑\(change)")
                        .font(style.font)
                        .foregroundColor(.themeRemus)
                } else {
                    Text(verbatim: "↓\(abs(change))")
                        .font(style.font)
                        .foregroundColor(.themeLucian)
                }
            }
        }
        .padding(.horizontal, .margin6)
        .padding(.vertical, .margin2)
        .background(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(style.backgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous))
    }
}

extension BadgeViewNew {
    enum Style {
        case small
        case medium

        var font: Font {
            switch self {
            case .small: return .themeMicroSB
            case .medium: return .themeCaptionSB
            }
        }

        var foregroundColor: Color {
            switch self {
            case .small: return .themeBran
            case .medium: return .white
            }
        }

        var backgroundColor: Color {
            switch self {
            case .small: return .themeBlade
            case .medium: return .themeBlade
            }
        }
    }
}
