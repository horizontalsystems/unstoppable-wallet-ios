import UIKit
import ThemeKit
import StorageKit

struct MainModule {

    enum Tab: Int {
        case market, balance, transactions, settings
    }

    static func instance(presetTab: Tab? = nil) -> UIViewController {
        let service = MainService(
                localStorage: App.shared.localStorage,
                storage: StorageKit.LocalStorage.default,
                launchScreenManager: App.shared.launchScreenManager,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                walletConnectV2Manager: App.shared.walletConnectV2SessionManager,
                presetTab: presetTab
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
        let deepLinkService = DeepLinkService(deepLinkManager: App.shared.deepLinkManager)

        let viewModel = MainViewModel(service: service, badgeService: badgeService, releaseNotesService: releaseNotesService, jailbreakService: jailbreakService, deepLinkService: deepLinkService)
        let viewController = MainViewController(viewModel: viewModel)

        App.shared.pinKitDelegate.viewController = viewController

        return viewController
    }

}
