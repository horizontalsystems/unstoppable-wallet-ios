import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: IRestoreRouter {

    func showRestoreCoins(predefinedAccountType: PredefinedAccountType) {
        let module = RestoreCoinsRouter.module(presentationMode: .initial, predefinedAccountType: predefinedAccountType)
        viewController?.navigationController?.pushViewController(module, animated: true)
    }

}

extension RestoreRouter {

    static func module() -> UIViewController {
        let router = RestoreRouter()
        let presenter = RestorePresenter(router: router, accountCreator: App.shared.accountCreator, predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager)
        let viewController = RestoreViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    static func module(predefinedAccountType: PredefinedAccountType, mode: PresentationMode, delegate: IRestoreAccountTypeDelegate) -> UIViewController {
        switch predefinedAccountType {
        case .standard:
            return RestoreWordsRouter.module(mode: mode, wordsCount: 12, delegate: delegate)
        case .eos:
            return RestoreEosRouter.module(mode: mode, delegate: delegate)
        case .binance:
            return RestoreWordsRouter.module(mode: mode, wordsCount: 24, delegate: delegate)
        }
    }

    enum PresentationMode {
        case pushed
        case presented
    }

}
