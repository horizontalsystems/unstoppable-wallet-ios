import UIKit

struct MainSettingsModule {

    static func viewController() -> UIViewController {
        let service = MainSettingsService(
                backupManager: App.shared.backupManager,
                accountManager: App.shared.accountManager,
                pinKit: App.shared.pinKit,
                termsManager: App.shared.termsManager,
                themeManager: App.shared.themeManager,
                systemInfoManager: App.shared.systemInfoManager,
                currencyKit: App.shared.currencyKit,
                appConfigProvider: App.shared.appConfigProvider,
                walletConnectSessionManager: App.shared.walletConnectSessionManager,
                walletConnectV2SessionManager: App.shared.walletConnectV2SessionManager,
                launchScreenManager: App.shared.launchScreenManager
        )

        let viewModel = MainSettingsViewModel(service: service)

        return MainSettingsViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
