import UIKit

class GuideTextView: UITextView {

    init() {
        super.init(frame: .zero, textContainer: nil)

        backgroundColor = .clear
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        isEditable = false
        isScrollEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
