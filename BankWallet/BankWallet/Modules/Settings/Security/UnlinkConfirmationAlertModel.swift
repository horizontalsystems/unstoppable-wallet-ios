import UIKit
import GrouviActionSheet

class UnlinkConfirmationAlertModel: BaseAlertModel {
    var confirmItems = [ConfirmationCheckboxItem]()

    override open var cancelButtonTitle: String {
        return "alert.cancel".localized
    }

    override init() {
        super.init()

        var confirmTexts = [NSAttributedString]()

        let attributes = [NSAttributedStringKey.foregroundColor: ConfirmationTheme.textColor, NSAttributedStringKey.font: ConfirmationTheme.regularFont]
        confirmTexts.append(NSAttributedString(string: "settings_security.import_wallet_confirmation_1".localized, attributes: attributes))
        confirmTexts.append(NSAttributedString(string: "settings_security.import_wallet_confirmation_2".localized, attributes: attributes))

        let buttonItem = UnlinkButtonItem(tag: confirmItems.count, required: true, onTap: {
            self.dismiss?(true)
        })

        confirmTexts.enumerated().forEach { index, string in
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

}

extension UnlinkConfirmationAlertModel {

    static func show(from controller: UIViewController?, onDismiss: ((Bool) -> ())? = nil) {
        let model = UnlinkConfirmationAlertModel()
        let actionSheetController = ActionSheetController(withModel: model, actionSheetThemeConfig: AppTheme.actionSheetConfig)
        actionSheetController.backgroundColor = AppTheme.actionSheetBackgroundColor
        actionSheetController.onDismiss = { success in
            onDismiss?(success)
        }
        actionSheetController.contentBackgroundColor = .white
        actionSheetController.show(fromController: controller)
    }

}
