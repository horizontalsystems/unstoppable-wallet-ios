import UIKit

class GuestRouter {
    weak var viewController: UIViewController?
}

extension GuestRouter: IGuestRouter {

    func navigateToBackupRoutingToMain() {
        viewController?.present(BackupRouter.module(dismissMode: .toMain), animated: true)
    }

    func navigateToRestore() {
        viewController?.present(RestoreRouter.module(), animated: true)
    }

}

extension GuestRouter {

    static func module() -> UIViewController {
        let router = GuestRouter()
        let interactor = GuestInteractor(mnemonic: Factory.instance.mnemonicManager, localStorage: Factory.instance.userDefaultsStorage)
        let presenter = GuestPresenter(interactor: interactor, router: router)
        let viewController = GuestViewController(delegate: presenter)

        interactor.delegate = presenter
        router.viewController = viewController

        return viewController
    }

}
