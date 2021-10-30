import ThemeKit
import EthereumKit

struct AddTokenModule {

    static func viewController() -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let ethereumService = AddEvmTokenBlockchainService(blockchain: .ethereum, networkManager: App.shared.networkManager)
        let binanceSmartChainService = AddEvmTokenBlockchainService(blockchain: .binanceSmartChain, networkManager: App.shared.networkManager)
        let binanceService = AddBep2TokenBlockchainService(networkManager: App.shared.networkManager)

        let services: [IAddTokenBlockchainService] = [ethereumService, binanceSmartChainService, binanceService]

        let service = AddTokenService(account: account, blockchainServices: services, coinManager: App.shared.coinManager, walletManager: App.shared.walletManager)
        let viewModel = AddTokenViewModel(service: service)
        let viewController = AddTokenViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
