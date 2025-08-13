import SwiftUI

struct BadgeViewNew: View {
    private let text: String
    private let change: Int?
    private let mode: Mode
    private let colorStyle: ColorStyle

    init(_ text: CustomStringConvertible, change: Int? = nil, mode: BadgeViewNew.Mode? = nil, colorStyle: ColorStyle? = nil) {
        if let componentBadge = text as? ComponentBadge {
            self.text = componentBadge.text
            self.change = change ?? componentBadge.change
            self.mode = mode ?? componentBadge.mode ?? .solid
            self.colorStyle = colorStyle ?? componentBadge.colorStyle ?? .primary
        } else {
            self.text = text.description
            self.change = change
            self.mode = mode ?? .solid
            self.colorStyle = colorStyle ?? .primary
        }
    }

    var body: some View {
        switch mode {
        case .solid:
            content().background(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(Color.themeBlade))
        case .transparent:
            content().background(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).stroke(colorStyle.color(), lineWidth: .heightOneDp))
        }
    }

    @ViewBuilder func content() -> some View {
        HStack(spacing: .margin2) {
            ThemeText(text, style: .microSB, colorStyle: colorStyle)

            if let change, change != 0 {
                if change > 0 {
                    Text(verbatim: "↑\(change)")
                        .font(TextStyle.microSB.font)
                        .foregroundColor(ColorStyle.green.color())
                } else {
                    Text(verbatim: "↓\(abs(change))")
                        .font(TextStyle.microSB.font)
                        .foregroundColor(ColorStyle.red.color())
                }
            }
        }
        .padding(.horizontal, .margin6)
        .padding(.vertical, .margin2)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous))
    }
}

extension BadgeViewNew {
    enum Mode {
        case solid
        case transparent
    }
}
