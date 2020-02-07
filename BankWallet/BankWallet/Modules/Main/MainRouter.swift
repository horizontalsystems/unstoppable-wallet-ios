import UIKit
import ThemeKit

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

        App.shared.pinKitDelegate.viewController = viewController

        return viewController
    }

    private static var balanceNavigation: UIViewController {
        ThemeNavigationController(rootViewController: BalanceRouter.module())
    }

    private static var transactionsNavigation: UIViewController {
        ThemeNavigationController(rootViewController: TransactionsRouter.module())
    }

    private static var settingsNavigation: UIViewController {
        ThemeNavigationController(rootViewController: MainSettingsRouter.module())
    }

}
