import UIKit

class GuestRouter {
    weak var viewController: UIViewController?
}

extension GuestRouter: IGuestRouter {

    func navigateToBackupRoutingToMain() {
        viewController?.present(BackupRouter.module(dismissMode: .toSetPin), animated: true)
    }

    func navigateToRestore() {
        viewController?.present(RestoreRouter.module(), animated: true)
    }

}

extension GuestRouter {

    static func module() -> UIViewController {
        let router = GuestRouter()
        let interactor = GuestInteractor(wordsManager: App.shared.wordsManager, walletManager: App.shared.walletManager)
        let presenter = GuestPresenter(interactor: interactor, router: router)
        let viewController = GuestViewController(delegate: presenter)

        interactor.delegate = presenter
        router.viewController = viewController

        return viewController
    }

}
