import UIKit
import GrouviActionSheet

class UnlinkConfirmationViewController: BaseConfirmationViewController {

    override var texts: [NSAttributedString] {
        var texts = [NSAttributedString]()

        let attributes = [NSAttributedStringKey.foregroundColor: ConfirmationTheme.textColor, NSAttributedStringKey.font: ConfirmationTheme.regularFont]
        texts.append(NSAttributedString(string: "settings_security.import_wallet_confirmation_1".localized, attributes: attributes))
        texts.append(NSAttributedString(string: "settings_security.import_wallet_confirmation_2".localized, attributes: attributes))

        return texts
    }

    override func buttonItem(onTap: @escaping () -> ()) -> BaseButtonItem {
        return UnlinkButtonItem(tag: 2, required: true, onTap: onTap)
    }

}
