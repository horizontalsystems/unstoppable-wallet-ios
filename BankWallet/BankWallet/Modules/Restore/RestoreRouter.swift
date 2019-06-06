import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: IRestoreRouter {

    func openSyncMode(with words: [String]) {
        viewController?.navigationController?.pushViewController(SyncModeRouter.module(mode: .initial(words: words)), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreRouter {

    static func module() -> UIViewController {
        let router = RestoreRouter()
        let interactor = RestoreInteractor(wordsManager: App.shared.wordsManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RestorePresenter(interactor: interactor, router: router)
        let viewController = RestoreViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return WalletNavigationController(rootViewController: viewController)
    }

}
