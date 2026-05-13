import SwiftUI

struct BadgeView: View {
    private let text: String
    private let change: Int?
    private let mode: Mode
    private let color: Color
    private let onTap: (() -> Void)?

    init(_ text: CustomStringConvertible, change: Int? = nil, mode: Mode? = nil, color: Color? = nil) {
        if let componentBadge = text as? ComponentBadge {
            self.text = componentBadge.text
            self.change = change ?? componentBadge.change
            self.mode = mode ?? componentBadge.mode ?? .solid
            self.color = color ?? componentBadge.color ?? .primary
            onTap = componentBadge.onTap
        } else {
            self.text = text.description
            self.change = change
            self.mode = mode ?? .solid
            self.color = color ?? .primary
            onTap = nil
        }
    }

    var body: some View {
        if let onTap {
            Button(action: onTap) {
                bordered().contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            bordered()
        }
    }

    @ViewBuilder func bordered() -> some View {
        switch mode {
        case .solid:
            content().background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.themeBlade))
        case .transparent:
            content().background(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(color, lineWidth: 1))
        }
    }

    @ViewBuilder func content() -> some View {
        HStack(spacing: 2) {
            ThemeText(text, style: .microSB, color: color)

            if let change, change != 0 {
                if change > 0 {
                    Text(verbatim: "↑\(change)")
                        .font(TextStyle.microSB.font)
                        .foregroundColor(Color.lucian)
                } else {
                    Text(verbatim: "↓\(abs(change))")
                        .font(TextStyle.microSB.font)
                        .foregroundColor(Color.remus)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 1)
        .padding(.bottom, 2)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension BadgeView {
    enum Mode {
        case solid
        case transparent
    }
}
