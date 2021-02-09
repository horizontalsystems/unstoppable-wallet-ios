import UIKit
import ThemeKit

struct ManageWalletsModule {

    static func instance() -> UIViewController {
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

        let service = ManageWalletsService(
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                accountManager: App.shared.accountManager,
                enableCoinsService: enableCoinsService,
                blockchainSettingsService: blockchainSettingsService
        )

        let viewModel = ManageWalletsViewModel(service: service)

        let viewController = ManageWalletsViewController(
                viewModel: viewModel,
                blockchainSettingsView: blockchainSettingsView,
                enableCoinsView: enableCoinsView
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}
