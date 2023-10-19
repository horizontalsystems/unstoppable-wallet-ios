import UIKit

struct MainSettingsModule {
    static func viewController() -> UIViewController {
        let service = MainSettingsService(
            backupManager: App.shared.backupManager,
            cloudAccountBackupManager: App.shared.cloudBackupManager,
            accountRestoreWarningManager: App.shared.accountRestoreWarningManager,
            accountManager: App.shared.accountManager,
            contactBookManager: App.shared.contactManager,
            passcodeManager: App.shared.passcodeManager,
            termsManager: App.shared.termsManager,
            systemInfoManager: App.shared.systemInfoManager,
            currencyKit: App.shared.currencyKit,
            walletConnectSessionManager: App.shared.walletConnectSessionManager,
            subscriptionManager: App.shared.subscriptionManager,
            rateAppManager: App.shared.rateAppManager
        )

        let viewModel = MainSettingsViewModel(service: service)

        return MainSettingsViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }
}
