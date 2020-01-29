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
