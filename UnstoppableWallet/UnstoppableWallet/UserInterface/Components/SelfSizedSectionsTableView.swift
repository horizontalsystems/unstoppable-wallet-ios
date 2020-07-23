import UIKit
import SectionsTableView

class SelfSizedSectionsTableView: SectionsTableView {

    override init(style: Style) {
        super.init(style: style)

        backgroundColor = .clear
        separatorStyle = .none
        alwaysBounceVertical = false

        setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        contentSize
    }

}
