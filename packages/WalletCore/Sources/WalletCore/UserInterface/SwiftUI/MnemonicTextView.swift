import SwiftUI
import UIKit

struct MnemonicTextView: UIViewRepresentable {
    private static let minimumLines = 3
    private static let baseAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.body,
        .foregroundColor: UIColor.themeLeah,
    ]

    @Binding var value: CaretText
    let invalidRanges: [NSRange]
    @Binding var isFocused: Bool
    var identifier: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.font = .body
        textView.textColor = .themeLeah
        textView.tintColor = .themeInputFieldTintColor
        textView.keyboardAppearance = .themeDefault
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.smartInsertDeleteType = .no
        textView.inlinePredictionType = .no
        textView.textContentType = .init(rawValue: "")
        if #available(iOS 18.0, *) {
            textView.writingToolsBehavior = .none
        }
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.delegate = context.coordinator
        textView.accessibilityIdentifier = identifier

        apply(to: textView, coordinator: context.coordinator)

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        apply(to: uiView, coordinator: context.coordinator)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context _: Context) -> CGSize? {
        let minHeight = ceil(UIFont.body.lineHeight * CGFloat(Self.minimumLines))

        guard let width = proposal.width, width.isFinite else {
            let fitting = uiView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
            return CGSize(width: fitting.width, height: max(fitting.height, minHeight))
        }

        let fitting = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: max(fitting.height, minHeight))
    }

    /// Pushes SwiftUI state into the text view. Never writes bindings.
    private func apply(to textView: UITextView, coordinator: Coordinator) {
        if textView.markedTextRange == nil {
            applyContent(to: textView, coordinator: coordinator)
        } else if textView.text != value.text {
            // The model changed from outside (trash, suggestion) while an IME composition is in progress.
            // Commit the composition and re-apply outside of the view update; after `unmarkText()`
            // `markedTextRange` is nil, so the deferred pass cannot re-enter this branch.
            DispatchQueue.main.async { [weak textView, weak coordinator] in
                guard let textView, let coordinator else {
                    return
                }

                coordinator.isCommittingComposition = true
                textView.unmarkText()
                coordinator.isCommittingComposition = false

                coordinator.parent.applyContent(to: textView, coordinator: coordinator)
            }
        }
        // Otherwise: composing and the text is in sync; do not touch the text mid-composition.

        if isFocused, !textView.isFirstResponder, textView.window != nil {
            textView.becomeFirstResponder()
        } else if !isFocused, textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }

    /// Text, colouring and caret. Must only be called while `markedTextRange == nil`.
    private func applyContent(to textView: UITextView, coordinator: Coordinator) {
        // The value came from outside the text view (paste, scan, clear, suggestion, initial seed)
        // when it differs from what the text view itself last reported or what was last applied.
        let isExternalChange = value != coordinator.appliedValue

        if textView.text != value.text || coordinator.appliedInvalidRanges != invalidRanges {
            let attributedString = NSMutableAttributedString(string: value.text, attributes: Self.baseAttributes)
            let length = attributedString.length

            for range in invalidRanges {
                guard range.location >= 0, range.location < length else {
                    continue
                }

                let clamped = NSRange(location: range.location, length: min(range.length, length - range.location))
                attributedString.addAttribute(.foregroundColor, value: UIColor.themeLucian, range: clamped)
            }

            let savedSelection = textView.selectedRange
            textView.attributedText = attributedString
            textView.typingAttributes = Self.baseAttributes
            coordinator.appliedInvalidRanges = invalidRanges

            if !isExternalChange {
                // Only the colouring changed: keep the live caret / selection where the user left it.
                textView.selectedRange = Self.clamp(savedSelection, toLength: length)
            }
        }

        if isExternalChange {
            let caretRange = Self.clamp(NSRange(location: value.caretOffset, length: 0), toLength: (textView.text as NSString).length)
            if textView.selectedRange != caretRange {
                textView.selectedRange = caretRange
            }
        }

        coordinator.appliedValue = value
    }

    private static func clamp(_ range: NSRange, toLength length: Int) -> NSRange {
        let location = max(0, min(range.location, length))
        let rangeLength = max(0, min(range.length, length - location))
        return NSRange(location: location, length: rangeLength)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MnemonicTextView
        var appliedInvalidRanges: [NSRange] = []
        var appliedValue: CaretText?
        var isCommittingComposition = false

        init(parent: MnemonicTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            // A programmatic `unmarkText()` must not overwrite the pending external value.
            guard !isCommittingComposition else {
                return
            }

            let newValue = CaretText(text: textView.text, caretOffset: textView.selectedRange.location)
            appliedValue = newValue

            // Colouring deferred during an IME composition is applied here once the composition commits
            // without a text change. Setting `attributedText` programmatically does not re-fire `textViewDidChange`.
            if parent.value != newValue {
                parent.value = newValue
            } else if textView.markedTextRange == nil, appliedInvalidRanges != parent.invalidRanges {
                parent.applyContent(to: textView, coordinator: self)
            }
        }

        func textViewDidBeginEditing(_: UITextView) {
            if !parent.isFocused {
                parent.isFocused = true
            }
        }

        func textViewDidEndEditing(_: UITextView) {
            if parent.isFocused {
                parent.isFocused = false
            }
        }
    }
}
