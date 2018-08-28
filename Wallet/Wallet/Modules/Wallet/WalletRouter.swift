import UIKit

class WalletRouter {
    weak var viewController: UIViewController?
}

extension WalletRouter: IWalletRouter {

    func onReceive(forAdapterId adapterId: String) {
        DepositRouter.module(coins: []).show(fromController: viewController)
    }

    func onSend(forAdapterId adapterId: String) {
        SendRouter.module(coin: Bitcoin()).show(fromController: viewController)
    }

}

extension WalletRouter {

    static func module() -> UIViewController {
        let router = WalletRouter()
        let interactor = WalletInteractor(adapterManager: AdapterManager.shared, exchangeRateManager: ExchangeRateManager.shared)
        let presenter = WalletPresenter(interactor: interactor, router: router)
        let viewController = WalletViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
