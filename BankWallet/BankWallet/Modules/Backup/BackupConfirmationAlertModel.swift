import UIKit
import GrouviActionSheet

class BackupConfirmationAlertModel: BaseAlertModel {
    var confirmItems = [ConfirmationCheckboxItem]()

    override open var cancelButtonTitle: String {
        return "alert.cancel".localized
    }

    override init() {
        super.init()

        var confirmTexts = [NSAttributedString]()

        let confirm = "backup.confirmation.understand".localized
        let confirmAttributed = NSMutableAttributedString(string: confirm, attributes: [NSAttributedStringKey.foregroundColor: ConfirmationTheme.textColor, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17)])
        confirmAttributed.addAttribute(NSAttributedStringKey.font, value: ConfirmationTheme.regularFont, range: NSMakeRange(0, confirm.count))
        confirmTexts.append(confirmAttributed)
        confirmTexts.append(NSAttributedString(string: "backup.confirmation.delete_app_warn".localized, attributes: [NSAttributedStringKey.foregroundColor: ConfirmationTheme.textColor, NSAttributedStringKey.font: ConfirmationTheme.regularFont]))

        let buttonItem = ConfirmationButtonItem(tag: confirmItems.count, required: true, onTap: {
            self.dismiss?(true)
        })
        confirmTexts.enumerated().forEach { (index, string) in
            let item = ConfirmationCheckboxItem(descriptionText: string, tag: index, required: true) { [weak self] view in
                if let view = view as? ConfirmationCheckboxView, let item = view.item {
                    item.checked = !item.checked
                    buttonItem.isActive = (self?.confirmItems.filter { $0.checked == false })?.isEmpty ?? false
                    self?.reload?()
                }
            }
            item.showSeparator = false
            item.height =  ConfirmationCheckboxItem.height(for: string)
            addItemView(item)
            confirmItems.append(item)
        }

        addItemView(buttonItem)
    }

    static func show(from controller: UIViewController?, onDismiss: ((Bool) -> ())? = nil) {
        if App.shared.localStorage.iUnderstand {
            onDismiss?(true)
        } else {
            let model = BackupConfirmationAlertModel()
            let actionSheetController = ActionSheetController(withModel: model, actionSheetThemeConfig: AppTheme.actionSheetConfig)
            actionSheetController.backgroundColor = AppTheme.actionSheetBackgroundColor
            actionSheetController.onDismiss = { success in
                onDismiss?(success)
                if success {
                    App.shared.localStorage.iUnderstand = true
                }
            }
            actionSheetController.contentBackgroundColor = .white
            actionSheetController.show(fromController: controller)
        }
    }

}
