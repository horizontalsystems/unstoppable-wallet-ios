import UIKit
import GrouviActionSheet

class DepositButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.yellowBackgroundOnWhiteBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.textColorOnWhiteBackgroundDictionary }
    override var title: String { return "alert.share".localized }

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        super.init(cellType: DepositButtonItemView.self, tag: tag, hidden: hidden, required: required)

        self.onTap = onTap
        height = DepositTheme.shareButtonItemHeight
    }

}
