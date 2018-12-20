import UIKit
import GrouviActionSheet

class UnlinkButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.redBackgroundOnWhiteBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.whiteTextColorOnDarkBackgroundDictionary }
    override var title: String { return "security_settings.unlink_alert_button".localized }

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        super.init(cellType: AlertButtonItemView.self, tag: tag, hidden: hidden, required: required)

        self.onTap = onTap
        isActive = false
        height = ConfirmationTheme.buttonTopMargin + ConfirmationTheme.buttonHeight + ConfirmationTheme.smallMargin
        showSeparator = false
    }

}
