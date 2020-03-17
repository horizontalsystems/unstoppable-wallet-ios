import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: IRestoreRouter {

    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: ICredentialsCheckDelegate) {
        let restoreController = RestoreRouter.module(predefinedAccountType: predefinedAccountType, mode: .pushed, proceedMode: .next, delegate: delegate)
        viewController?.navigationController?.pushViewController(restoreController, animated: true)
    }

    func showSettings(coins: [Coin], delegate: IBlockchainSettingsDelegate?) {
        viewController?.navigationController?.pushViewController(BlockchainSettingsListRouter.module(selectedCoins: coins, proceedMode: .restore, canSave: false, delegate: delegate), animated: true)
    }

    func showRestoreCoins(predefinedAccountType: PredefinedAccountType, accountType: AccountType, proceedMode: RestoreRouter.ProceedMode, delegate: IRestoreCoinsDelegate?) {
        viewController?.navigationController?.pushViewController(RestoreCoinsRouter.module(proceedMode: proceedMode, predefinedAccountType: predefinedAccountType, accountType: accountType, delegate: delegate), animated: true)
    }

    func showMain() {
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .balance))
    }

}

extension RestoreRouter {

    static func module() -> UIViewController {
        let restoreSequenceFactory = RestoreSequenceFactory(walletManager: App.shared.walletManager, settingsManager: App.shared.coinSettingsManager, accountCreator: App.shared.accountCreator, accountManager: App.shared.accountManager)

        let router = RestoreRouter()
        let presenter = RestorePresenter(router: router, accountCreator: App.shared.accountCreator, predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager, restoreSequenceFactory: restoreSequenceFactory)
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
        case done
        case none
    }

}
