import UIKit
import GrouviActionSheet

class ConfirmationButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.yellowBackgroundOnWhiteBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.textColorOnWhiteBackgroundDictionary }
    override var title: String { return "alert.confirm".localized }

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        super.init(cellType: AlertButtonItemView.self, tag: tag, hidden: hidden, required: required)

        self.onTap = onTap
        isActive = false
        height = ConfirmationTheme.buttonTopMargin + ConfirmationTheme.buttonHeight + ConfirmationTheme.smallMargin
        showSeparator = false
    }

}
