import SwiftUI

struct MnemonicPhraseView: View {
    private let words: [String]
    private let hidden: Bool
    private let hint: String
    private let onTap: () -> Void

    init(words: [String], hidden: Bool, hint: String, onTap: @escaping () -> Void) {
        self.words = words
        self.hidden = hidden
        self.hint = hint
        self.onTap = onTap
    }

    var body: some View {
        ZStack {
            CenteredFlowLayout {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    HStack(alignment: .lastTextBaseline, spacing: .margin6) {
                        ThemeText("\(index + 1)", style: .subhead, colorStyle: .andy)
                        ThemeText(word, style: .body)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(hidden ? 0 : 1)
            .accessibilityHidden(hidden)

            if hidden {
                ThemeText(hint, style: .subheadR)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, .margin8) // card padding 16 + 8 = 24
            }
        }
        .padding(.vertical, .margin24)
        .padding(.horizontal, .margin16)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous).stroke(Color.themeBlade, lineWidth: .heightOneDp)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityAddTraits(.isButton)
    }
}
