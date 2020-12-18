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

        let service = ManageWalletsService(
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                accountManager: App.shared.accountManager
        )

        let viewModel = ManageWalletsViewModel(
                service: service,
                blockchainSettingsService: blockchainSettingsService
        )

        let viewController = ManageWalletsViewController(viewModel: viewModel, blockchainSettingsView: blockchainSettingsView)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
