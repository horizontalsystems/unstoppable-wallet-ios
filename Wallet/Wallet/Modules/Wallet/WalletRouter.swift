import UIKit

class WalletRouter {
    weak var viewController: UIViewController?
}

extension WalletRouter: IWalletRouter {

    func onReceive(forAdapterId adapterId: String) {
        DepositRouter.module(presentingViewController: viewController, adapterId: adapterId)
    }

    func onSend(forAdapterId adapterId: String) {
        if let adapter = App.shared.adapterManager.adapters.first(where: { adapterId == $0.id }) {
            SendRouter.module(adapter: adapter).show(fromController: viewController)
        }
    }

}

extension WalletRouter {

    static func module() -> UIViewController {
        let router = WalletRouter()
        let interactor = WalletInteractor(adapterManager: App.shared.adapterManager, exchangeRateManager: ExchangeRateManager.shared)
        let presenter = WalletPresenter(interactor: interactor, router: router)
        let viewController = WalletViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
