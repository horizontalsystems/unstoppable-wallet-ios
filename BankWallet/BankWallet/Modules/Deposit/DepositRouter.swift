import UIKit
import GrouviActionSheet

class DepositRouter {
    weak var viewController: UIViewController?
}

extension DepositRouter: IDepositRouter {

    func share(address: String) {
        let activityViewController = UIActivityViewController(activityItems: [address], applicationActivities: [])
        viewController?.present(activityViewController, animated: true, completion: nil)
    }

}

extension DepositRouter {

    static func module(coinCode: CoinCode?) -> ActionSheetController {
        let router = DepositRouter()
        let interactor = DepositInteractor(adapterManager: App.shared.adapterManager, pasteboardManager: App.shared.pasteboardManager)
        let presenter = DepositPresenter(interactor: interactor, router: router)
        let depositAlertModel = DepositAlertModel(viewDelegate: presenter, coinCode: coinCode)

        interactor.delegate = presenter
        presenter.view = depositAlertModel

        let viewController = ActionSheetController(withModel: depositAlertModel, actionSheetThemeConfig: AppTheme.actionSheetConfig)
        viewController.backgroundColor = .crypto_Dark_Bars

        router.viewController = viewController

        return viewController
    }

}
