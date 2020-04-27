import UIKit
import SectionsTableView

class SelfSizedSectionsTableView: SectionsTableView {
    var maxHeight: CGFloat = UIScreen.main.bounds.size.height

    override init(style: Style) {
        super.init(style: style)

        backgroundColor = .clear
        separatorStyle = .none
        alwaysBounceVertical = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reloadData() {
        super.reloadData()

        invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }

    override var intrinsicContentSize: CGSize {
        setNeedsLayout()
        layoutIfNeeded()

        let height = min(ceil(contentSize.height), maxHeight)
        return CGSize(width: contentSize.width, height: height)
    }

}
