import SwiftUI

struct HighlightedTextView: View {
    private let text: String
    private let style: Style

    init(text: String, style: Style = .warning) {
        self.text = text
        self.style = style
    }

    var body: some View {
        Text(text)
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.themeBran)
                .font(.themeSubhead2)
                .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(style.color.opacity(0.2)))
                .overlay(
                        RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).stroke(style.color, lineWidth: .heightOneDp)
                )
    }

}

extension HighlightedTextView {

    enum Style {
        case warning
        case alert

        var color: Color {
            switch self {
            case .warning: return .themeYellow
            case .alert: return .themeLucian
            }
        }
    }

}
