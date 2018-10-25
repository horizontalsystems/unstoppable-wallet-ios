import UIKit
import GrouviActionSheet

class BackupButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.yellowBackgroundOnWhiteBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.textColorOnWhiteBackgroundDictionary }
    override var title: String { return "backup.confirmation.confirm".localized }

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        super.init(cellType: BackupButtonItemView.self, tag: tag, hidden: hidden, required: required)

        self.onTap = onTap
        isActive = false
        height = BackupConfirmationTheme.buttonTopMargin + BackupConfirmationTheme.buttonHeight + BackupConfirmationTheme.smallMargin
    }

}
