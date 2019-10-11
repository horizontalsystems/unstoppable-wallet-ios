import UIKit

extension UITextView {

    static var debug: UITextView {
        let textView = UITextView()

        textView.backgroundColor = .clear
        textView.contentInset = UIEdgeInsets(top: 0, left: CGFloat.margin4x, bottom: 0, right: CGFloat.margin4x)
        textView.textColor = .appGray
        textView.font = .appSubhead2
        textView.isEditable = false

        return textView
    }

}
