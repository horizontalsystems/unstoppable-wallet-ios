import UIKit

class MainRouter {
    weak var viewController: UIViewController?
}

extension MainRouter: MainRouterProtocol {

}

extension MainRouter {

    static var viewController: UIViewController {
        let router = MainRouter()
        let presenter = MainPresenter(router: router)

        let viewControllers = [
            walletNavigation,
            transactionsNavigation,
            settingsNavigation
        ]

        let viewController = MainViewController(viewDelegate: presenter, viewControllers: viewControllers)

        router.viewController = viewController

        return viewController
    }

    private static var walletNavigation: UIViewController {
        let navigation = UINavigationController(rootViewController: WalletRouter.viewController)
        navigation.navigationBar.barStyle = .blackTranslucent
        navigation.navigationBar.tintColor = .walletOrange
        if #available(iOS 11.0, *) {
            navigation.navigationBar.prefersLargeTitles = true
        }
        return navigation
    }

    private static var transactionsNavigation: UIViewController {
        let navigation = UINavigationController(rootViewController: TransactionsRouter.viewController)
        navigation.navigationBar.barStyle = .blackTranslucent
        return navigation
    }

    private static var settingsNavigation: UIViewController {
        let navigation = UINavigationController(rootViewController: SettingsRouter.viewController)
        navigation.navigationBar.barStyle = .blackTranslucent
        if #available(iOS 11.0, *) {
            navigation.navigationBar.prefersLargeTitles = true
        }
        return navigation
    }

}
