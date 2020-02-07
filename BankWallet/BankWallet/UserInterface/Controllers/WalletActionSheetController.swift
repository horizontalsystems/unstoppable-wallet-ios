import UIKit
import ActionSheet

class WalletActionSheetController: ActionSheetController {
    private static var defaultActionSheetConfig: ActionSheetThemeConfig {
        get {
            ActionSheetThemeConfig(
                    actionStyle: .sheet(showDismiss: false),
                    topMargin: 0,
                    cornerRadius: 16,
                    separatorColor: .themeSteel20,
                    backgroundStyle: .color(color: .themeBlack50)
            )
        }
    }

    override init(withModel model: BaseAlertModel = BaseAlertModel(), actionSheetThemeConfig: ActionSheetThemeConfig = WalletActionSheetController.defaultActionSheetConfig, customCancelButtonTitle: String? = nil) {
        super.init(withModel: model, actionSheetThemeConfig: actionSheetThemeConfig, customCancelButtonTitle: customCancelButtonTitle)

        App.shared.debugLogger?.add(log: "Init \(String(describing: type(of: self)))")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = .themeLawrence
    }

    deinit {
        App.shared.debugLogger?.add(log: "Deinit \(String(describing: type(of: self)))")
    }

}
