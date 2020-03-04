import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: IRestoreRouter {

    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: ICredentialsCheckDelegate) {
        let restoreController = RestoreRouter.module(predefinedAccountType: predefinedAccountType, mode: .pushed, proceedMode: .next, delegate: delegate)
        viewController?.navigationController?.pushViewController(restoreController, animated: true)
    }

    func showSettings(delegate: IBlockchainSettingsDelegate) {
        viewController?.navigationController?.pushViewController(BlockchainSettingsRouter.module(proceedMode: .next, delegate: delegate), animated: true)
    }

    func showRestoreCoins(predefinedAccountType: PredefinedAccountType, accountType: AccountType, delegate: IRestoreCoinsDelegate) {
        viewController?.navigationController?.pushViewController(RestoreCoinsRouter.module(predefinedAccountType: predefinedAccountType, accountType: accountType, delegate: delegate), animated: true)
    }

    func showMain() {
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .balance))
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

    static func module(predefinedAccountType: PredefinedAccountType, mode: RestoreRouter.PresentationMode, proceedMode: RestoreRouter.ProceedMode? = nil, delegate: ICredentialsCheckDelegate) -> UIViewController {
        switch predefinedAccountType {
        case .standard:
            return RestoreWordsRouter.module(presentationMode: mode, proceedMode: proceedMode ?? .next, wordsCount: 12, delegate: delegate)
        case .eos:
            return RestoreEosRouter.module(presentationMode: mode, proceedMode: proceedMode ?? .restore, delegate: delegate)
        case .binance:
            return RestoreWordsRouter.module(presentationMode: mode, proceedMode: proceedMode ?? .restore, wordsCount: 24, delegate: delegate)
        }
    }

    enum PresentationMode {
        case pushed
        case presented
    }

    enum ProceedMode {
        case next
        case restore
        case none
    }

}
