import UIKit
import ActionSheet

class DepositShareButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.greenBackgroundOnWhiteBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.textColorOnWhiteBackgroundDictionary }
    override var title: String { return "button.forward".localized }

    init(tag: Int, onTap: @escaping (() -> ())) {
        super.init(cellType: DepositShareButtonItemView.self, tag: tag, required: true)

        self.onTap = onTap
        height = DepositTheme.shareButtonItemHeight
        showSeparator = false
    }

}
