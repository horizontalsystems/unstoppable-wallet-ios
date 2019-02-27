import UIKit
import GrouviActionSheet

class BackupConfirmationViewController: BaseConfirmationViewController {

    override var texts: [NSAttributedString] {
        var texts = [NSAttributedString]()

        let confirm = "backup.confirmation.understand".localized
        let confirmAttributed = NSMutableAttributedString(string: confirm, attributes: [NSAttributedStringKey.foregroundColor: ConfirmationTheme.textColor, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17)])
        confirmAttributed.addAttribute(NSAttributedStringKey.font, value: ConfirmationTheme.regularFont, range: NSMakeRange(0, confirm.count))
        texts.append(confirmAttributed)
        texts.append(NSAttributedString(string: "backup.confirmation.delete_app_warn".localized, attributes: [NSAttributedStringKey.foregroundColor: ConfirmationTheme.textColor, NSAttributedStringKey.font: ConfirmationTheme.regularFont]))

        return texts
    }

    override func buttonItem(onTap: @escaping () -> ()) -> BaseButtonItem {
        return ConfirmationButtonItem(tag: 2, required: true, onTap: onTap)
    }

}

extension BaseConfirmationViewController {

    static func show(from controller: UIViewController?, onConfirm: @escaping () -> ()) {
        if App.shared.localStorage.iUnderstand {
            onConfirm()
        } else {
            let viewController = BackupConfirmationViewController(onConfirm: {
                App.shared.localStorage.iUnderstand = true
                onConfirm()
            })
            controller?.present(viewController, animated: true)
        }
    }

}
