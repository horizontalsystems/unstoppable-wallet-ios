import UIKit
import WalletKit
import GrouviActionSheet

class DepositRouter {
    weak var viewController: UIViewController?
}

extension DepositRouter: IDepositRouter {

    func onReceive(for walletBalance: WalletBalanceItem) {
        print("open receive alert")
    }

}

extension DepositRouter {

    static func module(walletBalances: [WalletBalanceItem]) -> ActionSheetController {
        let router = DepositRouter()
        let interactor = DepositInteractor(wallets: walletBalances)
        let presenter = DepositPresenter(interactor: interactor, router: router)
        let depositAlertModel = DepositAlertModel(viewDelegate: presenter)
        let viewController = ActionSheetController(withModel: depositAlertModel, actionStyle: .sheet(showDismiss: false))

        interactor.delegate = presenter
        presenter.view = depositAlertModel
        router.viewController = viewController

        return viewController
    }

}
