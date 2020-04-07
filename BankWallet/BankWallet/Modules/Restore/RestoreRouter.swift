import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: IRestoreRouter {

    func showRestore(predefinedAccountType: PredefinedAccountType) {
        let restoreController = RestoreRouter.module(predefinedAccountType: predefinedAccountType, initialRestore: true)
        viewController?.navigationController?.pushViewController(restoreController, animated: true)
    }

}

extension RestoreRouter {

    static func module() -> UIViewController {
        let router = RestoreRouter()
        let presenter = RestorePresenter(router: router, predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager)
        let viewController = RestoreViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    static func module(predefinedAccountType: PredefinedAccountType, initialRestore: Bool = false, selectCoins: Bool = true) -> UIViewController {
        let router = RestoreAccountTypeRouter(predefinedAccountType: predefinedAccountType, initialRestore: initialRestore)
        let handler = RestoreAccountTypeHandler(router: router, restoreManager: App.shared.restoreManager, selectCoins: selectCoins)

        let viewController: UIViewController

        switch predefinedAccountType {
        case .standard:
            viewController = RestoreWordsRouter.module(handler: handler, wordsCount: 12)
        case .eos:
            viewController = RestoreEosRouter.module(handler: handler)
        case .binance:
            viewController = RestoreWordsRouter.module(handler: handler, wordsCount: 24)
        }

        router.viewController = viewController

        return viewController
    }

    enum ProceedMode {
        case next
        case restore
        case done
        case none
    }

}
