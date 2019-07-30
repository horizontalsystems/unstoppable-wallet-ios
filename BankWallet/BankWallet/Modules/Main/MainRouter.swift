import UIKit

class MainRouter {
    weak var viewController: UIViewController?
}

extension MainRouter: IMainRouter {
}

extension MainRouter {

    enum Tab: Int {
        case balance, transactions, settings
    }

    static func module(selectedTab: Tab = .balance) -> UIViewController {
        let router = MainRouter()
        let interactor = MainInteractor(localStorage: App.shared.localStorage)
        let presenter = MainPresenter(interactor: interactor, router: router)

        let viewControllers = [
            balanceNavigation,
            transactionsNavigation,
            settingsNavigation
        ]

        let viewController = MainViewController(viewDelegate: presenter, viewControllers: viewControllers, selectedIndex: selectedTab.rawValue)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        App.shared.lockRouter.viewController = viewController

        return viewController
    }

    private static var balanceNavigation: UIViewController {
        return WalletNavigationController(rootViewController: BalanceRouter.module())
    }

    private static var transactionsNavigation: UIViewController {
        return WalletNavigationController(rootViewController: TransactionsRouter.module())
    }

    private static var settingsNavigation: UIViewController {
        return WalletNavigationController(rootViewController: MainSettingsRouter.module())
    }

}
