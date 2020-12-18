import UIKit

struct RestoreSelectCoinsModule {

    static func viewController(predefinedAccountType: PredefinedAccountType, restoreView: RestoreView) -> UIViewController {
        let blockchainSettingsService = BlockchainSettingsService(
                derivationSettingsManager: App.shared.derivationSettingsManager,
                bitcoinCashCoinTypeManager: App.shared.bitcoinCashCoinTypeManager
        )

        let blockchainSettingsViewModel = BlockchainSettingsViewModel(service: blockchainSettingsService)
        let blockchainSettingsView = BlockchainSettingsView(viewModel: blockchainSettingsViewModel)

        let service = RestoreSelectCoinsService(
                predefinedAccountType: predefinedAccountType,
                coinManager: App.shared.coinManager
        )

        let viewModel = RestoreSelectCoinsViewModel(
                service: service,
                blockchainSettingsService: blockchainSettingsService
        )

        return RestoreSelectCoinsViewController(restoreView: restoreView, viewModel: viewModel, blockchainSettingsView: blockchainSettingsView)
    }

}
