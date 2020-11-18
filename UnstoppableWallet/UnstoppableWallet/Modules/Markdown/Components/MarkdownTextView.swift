import UIKit
import ThemeKit

class MarkdownTextView: UITextView {

    init() {
        super.init(frame: .zero, textContainer: nil)

        backgroundColor = .clear
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        isEditable = false
        isScrollEnabled = false

        linkTextAttributes = [
            .foregroundColor: UIColor.themeJacob,
            .underlineColor: UIColor.themeJacob,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
