import Foundation

class WalletRouter {
    weak var viewController: UIViewController?
}

extension WalletRouter: IWalletRouter {
}

extension WalletRouter {

    static func module() -> UIViewController {
        let router = WalletRouter()
        let interactor = WalletInteractor(databaseManager: Factory.instance.databaseManager, unspentOutputUpdateSubject: Factory.instance.unspentOutputUpdateSubject, exchangeRateUpdateSubject: Factory.instance.exchangeRateUpdateSubject)
        let presenter = WalletPresenter(interactor: interactor, router: router)
        let viewController = WalletViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
