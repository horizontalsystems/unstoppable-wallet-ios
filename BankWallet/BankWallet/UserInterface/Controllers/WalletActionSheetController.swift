import UIKit
import ActionSheet

class WalletActionSheetController: ActionSheetController {

    override init(withModel model: BaseAlertModel, actionSheetThemeConfig: ActionSheetThemeConfig, customCancelButtonTitle: String? = nil) {
        super.init(withModel: model, actionSheetThemeConfig: actionSheetThemeConfig, customCancelButtonTitle: customCancelButtonTitle)

        App.shared.debugLogger?.add(log: "Init \(String(describing: type(of: self)))")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        App.shared.debugLogger?.add(log: "Deinit \(String(describing: type(of: self)))")
    }

}
