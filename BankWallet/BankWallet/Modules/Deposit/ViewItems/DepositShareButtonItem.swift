import UIKit
import ActionSheet

class DepositShareButtonItem: BaseButtonItem {
    override var createButton: UIButton { .appGreen }
    override var title: String { "button.share".localized }

    init(tag: Int, onTap: @escaping (() -> ())) {
        super.init(cellType: DepositShareButtonItemView.self, tag: tag, required: true)

        self.onTap = onTap

        height = CGFloat.heightButton + CGFloat.margin4x * 2
        showSeparator = false
    }

}
