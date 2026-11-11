import SwiftUI
import UIKit

struct MaskedInputTextFieldView: UIViewRepresentable {
    private static let secureSymbol = "•"
    private static let revealDuration: TimeInterval = 1

    let placeholder: String
    let text: Binding<String>
    @Binding var secured: Bool
    let isEnabled: Bool
    var placeholderColor: UIColor = .themeGray50
    var identifier: String?
    /// Mirrors the text field's first-responder state; `@FocusState` does not track a representable's UITextField
    var isFocused: Binding<Bool>?
    /// A change of this value asks the field to take focus, e.g. after a tap on the paddings around it
    var focusRequest = 0

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
        textField.accessibilityIdentifier = identifier
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor]
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
        context.coordinator.onChangeFocus = focusHandler()
        context.coordinator.handledFocusRequest = focusRequest
        context.coordinator.apply(textField: textField, text: text.wrappedValue, secured: secured)

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor]
        )
        textField.isEnabled = isEnabled
        textField.accessibilityIdentifier = identifier
        textField.textColor = isEnabled ? .themeLeah : .themeAndy

        context.coordinator.onChangeText = { text.wrappedValue = $0 }
        context.coordinator.onChangeFocus = focusHandler()
        context.coordinator.apply(textField: textField, text: text.wrappedValue, secured: secured)

        if context.coordinator.handledFocusRequest != focusRequest {
            context.coordinator.handledFocusRequest = focusRequest

            // taking focus marks a focus report as pending, so `reconcileFocus` below leaves it alone
            if isEnabled, !textField.isFirstResponder, textField.window != nil {
                textField.becomeFirstResponder()
            }
        }

        reconcileFocus(textField: textField, coordinator: context.coordinator)
    }

    static func dismantleUIView(_ textField: UITextField, coordinator: Coordinator) {
        let onChangeFocus = coordinator.onChangeFocus
        let hadFocus = textField.isFirstResponder || coordinator.isFocusSyncPending
        coordinator.onChangeFocus = nil

        // a field removed while focused (e.g. Advanced toggled off) must not leave its binding true,
        // or the field would grab focus when it is shown again
        if hadFocus {
            DispatchQueue.main.async {
                onChangeFocus?(false)
            }
        }
    }

    /// Pushes the binding into UIKit. Skipped while a delegate focus report is pending: until it lands the binding
    /// still holds the old value, and acting on it would undo the user's own tap into or out of the field.
    private func reconcileFocus(textField: UITextField, coordinator: Coordinator) {
        guard let isFocused, !coordinator.isFocusSyncPending else {
            return
        }

        if isFocused.wrappedValue, !textField.isFirstResponder {
            if textField.window != nil {
                if !textField.becomeFirstResponder() {
                    // refused: report the real state, so the binding reads false and a later request tries again
                    coordinator.syncFocus(textField)
                }
            } else if !coordinator.isFocusRetryScheduled {
                // requested before the field is in a window, e.g. from onAppear: one retry once it is attached
                coordinator.isFocusRetryScheduled = true

                DispatchQueue.main.async { [weak textField, weak coordinator] in
                    guard let coordinator, let textField else {
                        return
                    }

                    coordinator.isFocusRetryScheduled = false

                    guard isFocused.wrappedValue, !textField.isFirstResponder else {
                        return
                    }

                    if textField.window == nil || !textField.becomeFirstResponder() {
                        coordinator.syncFocus(textField)
                    }
                }
            }
        } else if !isFocused.wrappedValue, textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }

    private func focusHandler() -> ((Bool) -> Void)? {
        guard let isFocused else {
            return nil
        }

        return { focused in
            if isFocused.wrappedValue != focused {
                isFocused.wrappedValue = focused
            }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var onChangeText: ((String) -> Void)?
        var onChangeFocus: ((Bool) -> Void)?
        var isFocusRetryScheduled = false
        var handledFocusRequest = 0
        private var pendingFocusSyncs = 0

        var isFocusSyncPending: Bool {
            pendingFocusSyncs > 0
        }

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

        /// UIKit flips `isFirstResponder` before it calls the did-begin/did-end delegate methods, and SwiftUI can run
        /// `updateUIView` in between. Marking the report as pending here keeps `reconcileFocus` from undoing the
        /// change in that window.
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            syncFocus(textField)
            return true
        }

        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            syncFocus(textField)
            return true
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            syncFocus(textField)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            syncFocus(textField)
        }

        /// Reports UIKit's real first-responder state to the binding after the current pass, so the write
        /// never lands inside another view's update
        func syncFocus(_ textField: UITextField) {
            pendingFocusSyncs += 1

            DispatchQueue.main.async { [weak self, weak textField] in
                guard let self else {
                    return
                }

                pendingFocusSyncs -= 1
                onChangeFocus?(textField?.isFirstResponder ?? false)
            }
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
