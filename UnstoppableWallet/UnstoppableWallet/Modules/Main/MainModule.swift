import UIKit
import ThemeKit

struct MainModule {

    enum Tab: Int {
        case market, balance, transactions, settings
    }

    static func instance(selectedTab: Tab = .market) -> UIViewController {
        let showService = MainShowService(localStorage: App.shared.localStorage)
        let badgeService = MainBadgeService(
                backupManager: App.shared.backupManager,
                pinKit: App.shared.pinKit,
                termsManager: App.shared.termsManager
        )

        let viewModel = MainViewModel(showService: showService, badgeService: badgeService)

        let viewControllers = [
            marketNavigation,
            balanceNavigation,
            transactionsNavigation,
            settingsNavigation,
        ]

        let viewController = MainViewController(viewModel: viewModel, viewControllers: viewControllers, selectedIndex: selectedTab.rawValue)

        App.shared.pinKitDelegate.viewController = viewController

        return viewController
    }

    private static var marketNavigation: UIViewController {
        ThemeNavigationController(rootViewController: MarketModule.viewController())
    }

    private static var balanceNavigation: UIViewController {
        ThemeNavigationController(rootViewController: BalanceRouter.module())
    }

    private static var transactionsNavigation: UIViewController {
        ThemeNavigationController(rootViewController: TransactionsRouter.module())
    }

    private static var settingsNavigation: UIViewController {
        ThemeNavigationController(rootViewController: MainSettingsModule.viewController())
    }

}
