import UIKit
import RxSwift

struct RestoreSelectCoinsModule {

    static func viewController(predefinedAccountType: PredefinedAccountType, accountType: AccountType, restoreView: RestoreView) -> UIViewController {
        let blockchainSettingsService = BlockchainSettingsService(
                derivationSettingsManager: App.shared.derivationSettingsManager,
                bitcoinCashCoinTypeManager: App.shared.bitcoinCashCoinTypeManager
        )

        let blockchainSettingsViewModel = BlockchainSettingsViewModel(service: blockchainSettingsService)
        let blockchainSettingsView = BlockchainSettingsView(viewModel: blockchainSettingsViewModel)

        let enableCoinsService = EnableCoinsService(
                appConfigProvider: App.shared.appConfigProvider,
                ethereumProvider: EnableCoinsErc20Provider(networkManager: App.shared.networkManager),
                binanceProvider: EnableCoinsBep2Provider(appConfigProvider: App.shared.appConfigProvider),
                coinManager: App.shared.coinManager
        )

        let enableCoinsViewModel = EnableCoinsViewModel(service: enableCoinsService)
        let enableCoinsView = EnableCoinsView(viewModel: enableCoinsViewModel)

        let service = RestoreSelectCoinsService(
                predefinedAccountType: predefinedAccountType,
                accountType: accountType,
                coinManager: App.shared.coinManager,
                enableCoinsService: enableCoinsService,
                blockchainSettingsService: blockchainSettingsService
        )

        let viewModel = RestoreSelectCoinsViewModel(service: service)

        return RestoreSelectCoinsViewController(
                restoreView: restoreView,
                viewModel: viewModel,
                blockchainSettingsView: blockchainSettingsView,
                enableCoinsView: enableCoinsView
        )
    }

}
