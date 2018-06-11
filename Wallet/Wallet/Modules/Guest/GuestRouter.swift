import Foundation

class GuestRouter {
    weak var viewController: UIViewController?
}

extension GuestRouter: GuestRouterProtocol {

    func showBackupRoutingToMain() {
        viewController?.present(BackupRouter.module(dismissMode: .toMain), animated: true)
    }

    func showRestoreWallet() {
        viewController?.present(RestoreRouter.viewController, animated: true)
    }

}

extension GuestRouter {

    static var viewController: UIViewController {
        let router = GuestRouter()
        let interactor = GuestInteractor(mnemonic: Factory.instance.mnemonicManager, localStorage: Factory.instance.userDefaultsStorage)
        let presenter = GuestPresenter(delegate: interactor, router: router)
        let viewController = GuestViewController(viewDelegate: presenter)

        interactor.presenter = presenter
        router.viewController = viewController

        return viewController
    }

}
