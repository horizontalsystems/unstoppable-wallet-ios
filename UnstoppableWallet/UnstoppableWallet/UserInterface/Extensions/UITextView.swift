import UIKit

extension UITextView {

    static var appDebug: UITextView {
        let textView = UITextView()

        textView.backgroundColor = .clear
        textView.contentInset = UIEdgeInsets(top: 0, left: .margin4x, bottom: 0, right: .margin4x)
        textView.textColor = .themeGray
        textView.font = .subhead2
        textView.isEditable = false

        return textView
    }

}

extension UITextField {

    func textRange(range: NSRange) -> UITextRange? {
        let beginning = beginningOfDocument
        guard let start = position(from: beginning, offset: range.location),
              let end = position(from: start, offset: range.length) else {
            return nil
        }

        return textRange(from: start, to: end)
    }

    func range(textRange: UITextRange) -> NSRange {
        let location = offset(from: beginningOfDocument, to: textRange.start)
        let length = offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }

}