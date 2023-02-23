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

    override func adjustedContentInsetDidChange() {
        super.adjustedContentInsetDidChange()

        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: contentSize.width, height: contentSize.height + adjustedContentInset.bottom)
    }

}
