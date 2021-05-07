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
        let releaseNotesService = ReleaseNotesService(
                appVersionManager: App.shared.appVersionManager
        )
        let jailbreakService = JailbreakService(
                localStorage: App.shared.localStorage,
                jailbreakTestManager: JailbreakTestManager()
        )

        let viewModel = MainViewModel(service: service, badgeService: badgeService, releaseNotesService: releaseNotesService, jailbreakService: jailbreakService)
        let viewController = MainViewController(viewModel: viewModel, selectedIndex: selectedTab.rawValue)

        App.shared.pinKitDelegate.viewController = viewController

        return viewController
    }

}
