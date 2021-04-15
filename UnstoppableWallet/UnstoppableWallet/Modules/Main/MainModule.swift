import UIKit
import ThemeKit

struct MainModule {

    enum Tab: Int {
        case market, balance, transactions, settings
    }

    static func instance(selectedTab: Tab = .market) -> UIViewController {
        let service = MainService(
                localStorage: App.shared.localStorage,
                accountManager: App.shared.accountManager
        )
        let badgeService = MainBadgeService(
                backupManager: App.shared.backupManager,
                pinKit: App.shared.pinKit,
                termsManager: App.shared.termsManager
        )
        let whatsNewService = WhatsNewService(
                appVersionManager: App.shared.appVersionManager
        )

        let viewModel = MainViewModel(service: service, badgeService: badgeService, whatsNewService: whatsNewService)
        let viewController = MainViewController(viewModel: viewModel, selectedIndex: selectedTab.rawValue)

        App.shared.pinKitDelegate.viewController = viewController

        return viewController
    }

}
