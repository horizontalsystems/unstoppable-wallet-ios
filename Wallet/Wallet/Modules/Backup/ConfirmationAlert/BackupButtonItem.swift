import UIKit
import GrouviActionSheet

class BackupButtonItem: BaseActionItem {

    let backgroundStyle = ButtonTheme.yellowBackgroundOnWhiteBackgroundDictionary
    let textStyle = ButtonTheme.textColorOnWhiteBackgroundDictionary

    let title = "backup.confirmation.confirm".localized
    var isActive = false

    let onTap: (() -> ())


    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        self.onTap = onTap

        super.init(cellType: BackupButtonItemView.self, tag: tag, hidden: hidden, required: required)

        height = BackupConfirmationTheme.buttonTopMargin + BackupConfirmationTheme.buttonHeight + BackupConfirmationTheme.smallMargin
    }

}
