import ThemeKit
import UIKit

enum MainModule {
    enum Tab: Int {
        case market, balance, transactions, settings
    }

    static func instance(presetTab: Tab? = nil) -> UIViewController {
        let service = MainService(
            localStorage: App.shared.localStorage,
            userDefaultsStorage: App.shared.userDefaultsStorage,
            launchScreenManager: App.shared.launchScreenManager,
            accountManager: App.shared.accountManager,
            walletManager: App.shared.walletManager,
            appManager: App.shared.appManager,
            passcodeManager: App.shared.passcodeManager,
            lockManager: App.shared.lockManager,
            presetTab: presetTab
        )
        let badgeService = MainBadgeService(
            backupManager: App.shared.backupManager,
            accountRestoreWarningManager: App.shared.accountRestoreWarningManager,
            passcodeManager: App.shared.passcodeManager,
            termsManager: App.shared.termsManager,
            walletConnectSessionManager: App.shared.walletConnectSessionManager,
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

        let eventHandler = App.shared.appEventHandler
        let viewModel = MainViewModel(
            service: service,
            badgeService: badgeService,
            releaseNotesService: releaseNotesService,
            jailbreakService: jailbreakService,
            deepLinkService: deepLinkService,
            eventHandler: eventHandler
        )

        let viewController = MainViewController(viewModel: viewModel)

        let deepLinkHandler = WalletConnectAppShowModule.handler(parentViewController: viewController)
        let widgetCoinHandler = WidgetCoinAppShowModule.handler(parentViewController: viewController)
        let sendAddressHandler = AddressAppShowModule.handler(parentViewController: viewController)
        eventHandler.append(handler: deepLinkHandler)
        eventHandler.append(handler: widgetCoinHandler)
        eventHandler.append(handler: sendAddressHandler)

        App.shared.lockDelegate.viewController = viewController

        return viewController
    }
}
