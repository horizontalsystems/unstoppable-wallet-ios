import UIKit
import ActionSheet

class DepositShareButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.greenBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.textColorDictionary }
    override var title: String { return "button.share".localized }

    init(tag: Int, onTap: @escaping (() -> ())) {
        super.init(cellType: DepositShareButtonItemView.self, tag: tag, required: true)

        self.onTap = onTap
        height = DepositTheme.shareButtonItemHeight
        showSeparator = false
    }

}
