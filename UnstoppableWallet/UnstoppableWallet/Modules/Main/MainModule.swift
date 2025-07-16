import UIKit

enum MainModule {
    enum Tab: String, CaseIterable {
        case markets, balance, transactions, settings
    }

    static func instance(presetTab: Tab? = nil) -> UIViewController {
        let service = MainService(
            localStorage: Core.shared.localStorage,
            userDefaultsStorage: Core.shared.userDefaultsStorage,
            launchScreenManager: Core.shared.launchScreenManager,
            accountManager: Core.shared.accountManager,
            walletManager: Core.shared.walletManager,
            appManager: Core.shared.appManager,
            passcodeManager: Core.shared.passcodeManager,
            lockManager: Core.shared.lockManager,
            presetTab: presetTab
        )
        let badgeService = MainBadgeService(
            backupManager: Core.shared.backupManager,
            accountRestoreWarningManager: Core.shared.accountRestoreWarningManager,
            passcodeManager: Core.shared.passcodeManager,
            termsManager: Core.shared.termsManager,
            walletConnectSessionManager: Core.shared.walletConnectSessionManager,
            contactBookManager: Core.shared.contactManager
        )
        let releaseNotesService = Core.shared.releaseNotesService
        let jailbreakService = JailbreakService(localStorage: Core.shared.localStorage)

        let eventHandler = Core.shared.appEventHandler
        let viewModel = MainViewModel(
            service: service,
            badgeService: badgeService,
            releaseNotesService: releaseNotesService,
            jailbreakService: jailbreakService,
            eventHandler: eventHandler
        )

        let viewController = MainViewController(viewModel: viewModel)

        // Core.shared.lockDelegate.viewController = viewController

        return viewController
    }
}
