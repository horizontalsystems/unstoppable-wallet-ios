import SwiftUI

// Hosts an amount text field bound to local text, so only accepted edits reach `text`. A rejected edit
// reverts the local text to `text`, shakes the content and fires a light haptic. Changes made to `text`
// from outside (view model sync, percent buttons, clearing) are copied into the field as-is, except that
// extra fraction digits are silently truncated as a safety net.
struct ValidatedAmountInput<Content: View>: View {
    @Binding var text: String
    let maxDecimals: Int
    @ViewBuilder let content: (Binding<String>) -> Content

    @State private var localText: String
    @State private var shake = false

    init(text: Binding<String>, maxDecimals: Int, @ViewBuilder content: @escaping (Binding<String>) -> Content) {
        _text = text
        self.maxDecimals = maxDecimals
        self.content = content
        _localText = State(initialValue: text.wrappedValue)
    }

    var body: some View {
        content($localText)
            .onChange(of: localText) { _, newValue in
                // Already in sync: an external change copied in, or a revert/replacement written below
                guard newValue != text else {
                    return
                }

                switch AmountInputValidator.validate(oldText: text, newText: newValue, maxDecimals: maxDecimals) {
                case .valid:
                    text = newValue
                case let .replaced(value):
                    localText = value
                    text = value
                case .invalid:
                    localText = text
                    shake = true
                    HapticGenerator.instance.notification(.feedback(.light))
                }
            }
            .onChange(of: text) { _, newValue in
                if localText != newValue {
                    localText = newValue
                }

                truncateExtraDecimals()
            }
            .onChange(of: maxDecimals, initial: true) {
                truncateExtraDecimals()
            }
            .shake($shake)
    }

    // A no-op for values that fit `maxDecimals`, so it never writes back what the view model produced itself
    private func truncateExtraDecimals() {
        let separator = AmountInputValidator.currentDecimalSeparator

        guard !AmountInputValidator.isValid(text, maxDecimals: maxDecimals, decimalSeparator: separator),
              let truncated = AmountInputValidator.truncated(text, maxDecimals: maxDecimals, decimalSeparator: separator),
              truncated != text
        else {
            return
        }

        localText = truncated
        text = truncated
    }
}
