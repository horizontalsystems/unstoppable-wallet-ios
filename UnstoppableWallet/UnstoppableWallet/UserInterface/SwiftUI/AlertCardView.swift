import SwiftUI

struct AlertCardView: View {
    private let title: String
    private let text: String
    private let style: Style

    init(title: String, text: String, style: Style = .warning) {
        self.title = title
        self.text = text
        self.style = style
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(spacing: 1) {
                Image("warning_filled").icon(size: .iconSize20, colorStyle: style.colorStyle)

                ThemeText(title, style: .headline2, colorStyle: style.colorStyle)
            }
            .padding(EdgeInsets(top: .margin16, leading: .margin24, bottom: 0, trailing: .margin24))

            ThemeText(text, style: .subheadR, colorStyle: .primary)
                .multilineTextAlignment(.center)
                .padding(EdgeInsets(top: .margin8, leading: .margin24, bottom: .margin16, trailing: .margin24))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous).stroke(style.colorStyle.color, lineWidth: .heightOneDp)
        )
    }
}

extension AlertCardView {
    enum Style {
        case warning, error

        var colorStyle: ColorStyle {
            switch self {
            case .warning: return .yellow
            case .error: return .red
            }
        }
    }
}
