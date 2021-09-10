import ThemeKit
import EthereumKit

struct AddTokenModule {

    static func viewController() -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let ethereumService = evmService(networkType: App.shared.accountSettingManager.ethereumNetwork(account: account).networkType)
        let binanceSmartChainService = evmService(networkType: App.shared.accountSettingManager.binanceSmartChainNetwork(account: account).networkType)
        let binanceService = AddBep2TokenBlockchainService(appConfigProvider: App.shared.appConfigProvider, networkManager: App.shared.networkManager)

        let services = [ethereumService, binanceSmartChainService, binanceService]

        let service = AddTokenService(account: account, blockchainServices: services, coinManager: App.shared.coinManagerNew, walletManager: App.shared.walletManagerNew)
        let viewModel = AddTokenViewModel(service: service)

        let viewController = AddTokenViewController(
                viewModel: viewModel,
                pageTitle: "add_token.title".localized,
                referenceTitle: "ERC20 / BEP20 / BEP2"
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

    private static func evmService(networkType: NetworkType) -> IAddTokenBlockchainService {
        AddEvmTokenBlockchainService(
                networkType: networkType,
                appConfigProvider: App.shared.appConfigProvider,
                networkManager: App.shared.networkManager
        )
    }

}
