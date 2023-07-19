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
                appManager: App.shared.appManager,
                pinKit: App.shared.pinKit,
                presetTab: presetTab
        )
        let badgeService = MainBadgeService(
                backupManager: App.shared.backupManager,
                accountRestoreWarningManager: App.shared.accountRestoreWarningManager,
                pinKit: App.shared.pinKit,
                termsManager: App.shared.termsManager,
                walletConnectV2SessionManager: App.shared.walletConnectV2SessionManager,
                contactBookManager: App.shared.contactManager
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

        let walletConnectWorkerService = WalletConnectV2AppShowService(
                walletConnectV2Manager: App.shared.walletConnectV2SessionManager,
                accountManager: App.shared.accountManager,
                pinKit: App.shared.pinKit)
        let walletConnectWorkerViewModel = WalletConnectV2AppShowViewModel(service: walletConnectWorkerService)
        let walletConnectWorkerView = WalletConnectV2AppShowView(
                viewModel: walletConnectWorkerViewModel,
                parentViewController: viewController)

        viewController.workers.append(walletConnectWorkerView)

        App.shared.pinKitDelegate.viewController = viewController

        return viewController
    }

}

protocol IMainWorker {}

protocol IDeepLinkHandler: IMainWorker {
    func handle(deepLink: DeepLinkManager.DeepLink)
}
