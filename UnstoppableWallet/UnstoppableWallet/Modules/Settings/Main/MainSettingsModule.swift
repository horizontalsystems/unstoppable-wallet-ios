import UIKit

struct MainSettingsModule {

    static func viewController() -> UIViewController {
        let service = MainSettingsService(
                backupManager: App.shared.backupManager,
                cloudAccountBackupManager: App.shared.cloudAccountBackupManager,
                accountRestoreWarningManager: App.shared.accountRestoreWarningManager,
                accountManager: App.shared.accountManager,
                contactBookManager: App.shared.contactManager,
                pinKit: App.shared.pinKit,
                termsManager: App.shared.termsManager,
                systemInfoManager: App.shared.systemInfoManager,
                currencyKit: App.shared.currencyKit,
                walletConnectSessionManager: App.shared.walletConnectSessionManager,
                walletConnectV2SessionManager: App.shared.walletConnectV2SessionManager,
                subscriptionManager: App.shared.subscriptionManager
        )

        let viewModel = MainSettingsViewModel(service: service)

        return MainSettingsViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
