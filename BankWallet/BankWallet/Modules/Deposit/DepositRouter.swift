import UIKit
import GrouviActionSheet

class DepositRouter {
}

extension DepositRouter: IDepositRouter {
}

extension DepositRouter {

    static func module(coinCode: CoinCode?) -> ActionSheetController {
        let router = DepositRouter()
        let interactor = DepositInteractor(walletManager: App.shared.walletManager, pasteboardManager: App.shared.pasteboardManager)
        let presenter = DepositPresenter(interactor: interactor, router: router)
        let depositAlertModel = DepositAlertModel(viewDelegate: presenter, coinCode: coinCode)

        interactor.delegate = presenter
        presenter.view = depositAlertModel

        let viewController = ActionSheetController(withModel: depositAlertModel, actionSheetThemeConfig: AppTheme.actionSheetConfig)
        viewController.backgroundColor = .cryptoBars
        return viewController
    }

}
