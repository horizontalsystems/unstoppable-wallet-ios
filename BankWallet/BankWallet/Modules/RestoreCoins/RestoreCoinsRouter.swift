import UIKit
import ThemeKit

class RestoreCoinsRouter {
    weak var viewController: UIViewController?

    weak var delegate: IRestoreCoinsDelegate?

    init(delegate: IRestoreCoinsDelegate) {
        self.delegate = delegate
    }

}

extension RestoreCoinsRouter: IRestoreCoinsRouter {

    func notifyRestored() {
        delegate?.didRestore()
    }

}

extension RestoreCoinsRouter {

    static func module(predefinedAccountType: PredefinedAccountType, accountType: AccountType, delegate: IRestoreCoinsDelegate) -> UIViewController {
        let router = RestoreCoinsRouter(delegate: delegate)
        let interactor = RestoreCoinsInteractor(
                appConfigProvider: App.shared.appConfigProvider,
                accountCreator: App.shared.accountCreator,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                coinSettingsManager: App.shared.coinSettingsManager
        )
        let presenter = RestoreCoinsPresenter(predefinedAccountType: predefinedAccountType, accountType: accountType, interactor: interactor, router: router)
        let viewController = RestoreCoinsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
