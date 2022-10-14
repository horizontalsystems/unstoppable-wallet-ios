import UIKit
import ThemeKit
import SnapKit

class MnemonicInputCell: TextInputCell {
    var onChangeMnemonicText: ((String, Int, String?) -> ())?
    var onChangeEntering: (() -> ())?

    private(set) var entering = false {
        didSet {
            onChangeEntering?()
        }
    }

    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)

        guard let selectedTextRange = textView.selectedTextRange else {
            return
        }

        let cursorOffset = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start)
        onChangeMnemonicText?(textView.text, cursorOffset, textView.textInputMode?.primaryLanguage)
    }

    override func textViewDidBeginEditing(_ textView: UITextView) {
        super.textViewDidBeginEditing(textView)

        entering = true
    }

    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)

        entering = false
    }

    override func set(text: String) {
        super.set(text: text)
        onChangeMnemonicText?(text, text.count, textView.textInputMode?.primaryLanguage)
    }

}

extension MnemonicInputCell {

    func set(invalidRanges: [NSRange]) {
        let attributedString = NSMutableAttributedString(string: textView.text, attributes: [
            .foregroundColor: textViewTextColor,
            .font: textViewFont
        ])

        for range in invalidRanges {
            attributedString.addAttribute(.foregroundColor, value: UIColor.themeLucian, range: range)
        }

        let range = textView.selectedRange
        textView.attributedText = attributedString
        textView.selectedRange = range
    }

    func replaceWord(range: NSRange, word: String) {
        var text: String = textView.text

        guard let textRange = Range(range, in: text) else {
            return
        }

        let replaceWord = word + " "
        text.replaceSubrange(textRange, with: replaceWord)

        super.set(text: text)

        let cursorOffset = range.lowerBound + replaceWord.count
        if let newPosition = textView.position(from: textView.beginningOfDocument, offset: cursorOffset) {
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
        }

        onChangeMnemonicText?(text, cursorOffset, textView.textInputMode?.primaryLanguage)
    }

}
