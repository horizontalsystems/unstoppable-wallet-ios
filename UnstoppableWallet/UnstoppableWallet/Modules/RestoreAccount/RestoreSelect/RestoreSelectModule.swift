import UIKit
import RxSwift

struct RestoreSelectModule {

    static func viewController(accountType: AccountType) -> UIViewController {
        let restoreSettingsService = RestoreSettingsService(manager: App.shared.restoreSettingsManager)
        let restoreSettingsViewModel = RestoreSettingsViewModel(service: restoreSettingsService)
        let restoreSettingsView = RestoreSettingsView(viewModel: restoreSettingsViewModel)

        let coinSettingsService = CoinSettingsService()
        let coinSettingsViewModel = CoinSettingsViewModel(service: coinSettingsService)
        let coinSettingsView = CoinSettingsView(viewModel: coinSettingsViewModel)

        let enableCoinsService = EnableCoinsService(
                appConfigProvider: App.shared.appConfigProvider,
                erc20Provider: EnableCoinsEip20Provider(appConfigProvider: App.shared.appConfigProvider, networkManager: App.shared.networkManager, mode: .erc20),
                bep20Provider: EnableCoinsEip20Provider(appConfigProvider: App.shared.appConfigProvider, networkManager: App.shared.networkManager, mode: .bep20),
                bep2Provider: EnableCoinsBep2Provider(appConfigProvider: App.shared.appConfigProvider),
                coinManager: App.shared.coinManager
        )

        let enableCoinsViewModel = EnableCoinsViewModel(service: enableCoinsService)
        let enableCoinsView = EnableCoinsView(viewModel: enableCoinsViewModel)

        let service = RestoreSelectService(
                accountType: accountType,
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                coinManager: App.shared.coinManager,
                enableCoinsService: enableCoinsService,
                restoreSettingsService: restoreSettingsService,
                coinSettingsService: coinSettingsService
        )

        let viewModel = RestoreSelectViewModel(service: service)

        return RestoreSelectViewController(
                viewModel: viewModel,
                restoreSettingsView: restoreSettingsView,
                coinSettingsView: coinSettingsView,
                enableCoinsView: enableCoinsView
        )
    }

}
