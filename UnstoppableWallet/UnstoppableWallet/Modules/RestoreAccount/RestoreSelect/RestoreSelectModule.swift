import UIKit
import RxSwift

struct RestoreSelectModule {

    static func viewController(accountType: AccountType) -> UIViewController {
        let coinSettingsService = CoinSettingsService()
        let coinSettingsViewModel = CoinSettingsViewModel(service: coinSettingsService)
        let coinSettingsView = CoinSettingsView(viewModel: coinSettingsViewModel)

        let enableCoinsService = EnableCoinsService(
                appConfigProvider: App.shared.appConfigProvider,
                erc20Provider: EnableCoinsErc20Provider(networkManager: App.shared.networkManager),
                bep20Provider: EnableCoinsBep20Provider(appConfigProvider: App.shared.appConfigProvider, networkManager: App.shared.networkManager),
                bep2Provider: EnableCoinsBep2Provider(appConfigProvider: App.shared.appConfigProvider),
                coinManager: App.shared.coinManager
        )

        let enableCoinsViewModel = EnableCoinsViewModel(service: enableCoinsService)
        let enableCoinsView = EnableCoinsView(viewModel: enableCoinsViewModel)

        let service = RestoreSelectService(
                accountType: accountType,
                coinManager: App.shared.coinManager,
                enableCoinsService: enableCoinsService,
                coinSettingsService: coinSettingsService
        )

        let viewModel = RestoreSelectViewModel(service: service)

        return RestoreSelectViewController(
                viewModel: viewModel,
                coinSettingsView: coinSettingsView,
                enableCoinsView: enableCoinsView
        )
    }

}
