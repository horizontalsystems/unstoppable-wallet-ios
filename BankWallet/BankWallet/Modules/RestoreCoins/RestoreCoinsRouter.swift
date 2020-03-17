import UIKit
import ThemeKit

class RestoreCoinsRouter {
    weak var viewController: UIViewController?

    weak var delegate: IRestoreCoinsDelegate?

    init(delegate: IRestoreCoinsDelegate?) {
        self.delegate = delegate
    }

}

extension RestoreCoinsRouter: IRestoreCoinsRouter {

    func onSelect(coins: [Coin]) {
        delegate?.onSelect(coins: coins)
    }

}

extension RestoreCoinsRouter {

    static func module(proceedMode: RestoreRouter.ProceedMode, predefinedAccountType: PredefinedAccountType, accountType: AccountType, delegate: IRestoreCoinsDelegate?) -> UIViewController {
        let router = RestoreCoinsRouter(delegate: delegate)
        let interactor = RestoreCoinsInteractor(appConfigProvider: App.shared.appConfigProvider)
        let presenter = RestoreCoinsPresenter(proceedMode: proceedMode, predefinedAccountType: predefinedAccountType, accountType: accountType, interactor: interactor, router: router)
        let viewController = RestoreCoinsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
