import SwiftUI

struct HighlightedTextView: View {
    private let title: String?
    private let text: String
    private let style: Style

    init(title: String? = nil, text: String, style: Style = .warning) {
        self.title = title
        self.text = text
        self.style = style
    }

    init(caution: CautionNew) {
        title = caution.title
        text = caution.text

        switch caution.type {
        case .warning: style = .warning
        case .error: style = .alert
        }
    }

    init(title: String? = nil, text: String, style: HighlightedDescriptionBaseView.Style) {
        self.title = title
        self.text = text

        switch style {
        case .yellow: self.style = .warning
        case .red: self.style = .alert
        }
    }

    var body: some View {
        VStack(spacing: .margin12) {
            if let title {
                HStack(spacing: .margin12) {
                    Image("warning_2_20").themeIcon(color: style.color)
                    Text(title).themeSubhead1(color: style.color)
                }
            }

            Text(text).themeSubhead2(color: .themeBran)
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
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
