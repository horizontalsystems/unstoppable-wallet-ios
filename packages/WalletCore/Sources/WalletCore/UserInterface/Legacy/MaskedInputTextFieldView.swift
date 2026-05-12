import SwiftUI
import UIKit

struct MaskedInputTextFieldView: UIViewRepresentable {
    private static let secureSymbol = "•"
    private static let revealDuration: TimeInterval = 1

    let placeholder: String
    let text: Binding<String>
    @Binding var secured: Bool
    let isEnabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: text.wrappedValue)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardAppearance = .themeDefault
        textField.tintColor = .themeInputFieldTintColor
        textField.textColor = .themeLeah
        textField.font = .body
        textField.backgroundColor = .clear
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.themeGray50]
        )
        textField.textContentType = .oneTimeCode
        textField.isSecureTextEntry = false
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.smartQuotesType = .no
        textField.smartDashesType = .no
        textField.smartInsertDeleteType = .no

        context.coordinator.onChangeText = { text.wrappedValue = $0 }
        context.coordinator.apply(textField: textField, text: text.wrappedValue, secured: secured)

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.themeGray50]
        )
        textField.isEnabled = isEnabled
        textField.textColor = isEnabled ? .themeLeah : .themeAndy

        context.coordinator.onChangeText = { text.wrappedValue = $0 }
        context.coordinator.apply(textField: textField, text: text.wrappedValue, secured: secured)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var onChangeText: ((String) -> Void)?

        private var text: String
        private var secured = false
        private var revealedLocation: Int?
        private var revealWorkItem: DispatchWorkItem?
        private var updatingTextField = false

        init(text: String) {
            self.text = text
        }

        func apply(textField: UITextField, text: String, secured: Bool) {
            if self.text != text {
                self.text = text
                revealedLocation = nil
            }
            self.secured = secured

            let cursorOffset = textField.selectedTextRange.map {
                textField.offset(from: textField.beginningOfDocument, to: $0.start)
            }
            updateDisplayedText(textField: textField, cursorOffset: cursorOffset)
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard !updatingTextField else {
                return true
            }

            let newText = (text as NSString).replacingCharacters(in: range, with: string)
            text = newText
            onChangeText?(newText)

            let cursorOffset = range.location + (string as NSString).length
            if secured, !string.isEmpty {
                revealedLocation = max(range.location, cursorOffset - 1)
                scheduleRevealHide(textField: textField)
            } else {
                revealedLocation = nil
                revealWorkItem?.cancel()
            }

            updateDisplayedText(textField: textField, cursorOffset: cursorOffset)
            return false
        }

        private func scheduleRevealHide(textField: UITextField) {
            revealWorkItem?.cancel()

            let workItem = DispatchWorkItem { [weak self, weak textField] in
                guard let self, let textField else {
                    return
                }

                revealedLocation = nil
                let cursorOffset = textField.selectedTextRange.map {
                    textField.offset(from: textField.beginningOfDocument, to: $0.start)
                }
                updateDisplayedText(textField: textField, cursorOffset: cursorOffset)
            }

            revealWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + MaskedInputTextFieldView.revealDuration, execute: workItem)
        }

        private func updateDisplayedText(textField: UITextField, cursorOffset: Int?) {
            let displayText = secured ? maskedText() : text

            guard textField.text != displayText else {
                return
            }

            updatingTextField = true
            textField.text = displayText

            let displayLength = (displayText as NSString).length
            let boundedCursorOffset = min(max(cursorOffset ?? displayLength, 0), displayLength)
            if let position = textField.position(from: textField.beginningOfDocument, offset: boundedCursorOffset) {
                textField.selectedTextRange = textField.textRange(from: position, to: position)
            }

            updatingTextField = false
        }

        private func maskedText() -> String {
            let nsText = text as NSString

            return (0 ..< nsText.length).map { location in
                location == revealedLocation ? nsText.substring(with: NSRange(location: location, length: 1)) : MaskedInputTextFieldView.secureSymbol
            }.joined()
        }
    }
}
