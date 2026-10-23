import SwiftUI

struct KeyCardView: View {
    private let text: String
    private let hidden: Bool
    private let hint: String?
    private let alignment: TextAlignment
    private let onTap: (() -> Void)?

    init(text: String, hidden: Bool = false, hint: String? = nil, alignment: TextAlignment = .leading, onTap: (() -> Void)? = nil) {
        self.text = text
        self.hidden = hidden
        self.hint = hint
        self.alignment = alignment
        self.onTap = onTap
    }

    var body: some View {
        ZStack {
            ThemeText(text, style: .subhead, colorStyle: .primary)
                .multilineTextAlignment(alignment)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
                .opacity(hidden ? 0 : 1)
                .accessibilityHidden(hidden)

            if hidden, let hint {
                ThemeText(hint, style: .subheadR)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, .margin24)
        .padding(.horizontal, .margin24)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous).stroke(Color.themeBlade, lineWidth: .heightOneDp)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .accessibilityAddTraits(onTap == nil ? [] : .isButton)
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}
