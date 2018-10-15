import UIKit

class MainRouter {
    weak var viewController: UIViewController?
}

extension MainRouter: IMainRouter {
}

extension MainRouter {

    static func module() -> UIViewController {
        let router = MainRouter()
        let interactor = MainInteractor()
        let presenter = MainPresenter(interactor: interactor, router: router)

        let viewControllers = [
            walletNavigation,
            transactionsNavigation,
            settingsNavigation
        ]

        let viewController = MainViewController(viewDelegate: presenter, viewControllers: viewControllers)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    private static var walletNavigation: UIViewController {
        let navigation = UINavigationController(rootViewController: WalletRouter.module())
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
