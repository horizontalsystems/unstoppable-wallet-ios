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
        let interactor = MainInteractor()
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
        let navigation = UINavigationController(rootViewController: BalanceRouter.module())
        navigation.navigationBar.barStyle = AppTheme.navigationBarStyle
        navigation.navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigation.navigationBar.prefersLargeTitles = true
        return navigation
    }

    private static var transactionsNavigation: UIViewController {
        let navigation = UINavigationController(rootViewController: TransactionsRouter.module())
        navigation.navigationBar.barStyle = AppTheme.navigationBarStyle
        navigation.navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigation.navigationBar.prefersLargeTitles = true
        return navigation
    }

    private static var settingsNavigation: UIViewController {
        let navigation = UINavigationController(rootViewController: MainSettingsRouter.module())
        navigation.navigationBar.barStyle = AppTheme.navigationBarStyle
        navigation.navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigation.navigationBar.prefersLargeTitles = true
        return navigation
    }

}
