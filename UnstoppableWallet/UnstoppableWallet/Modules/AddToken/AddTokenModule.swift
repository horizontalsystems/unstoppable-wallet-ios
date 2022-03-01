import ThemeKit
import EthereumKit

struct AddTokenModule {

    static func viewController() -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        var addTokenServices: [IAddTokenBlockchainService] = App.shared.evmBlockchainManager.allBlockchains.map {
            AddEvmTokenBlockchainService(blockchain: $0, networkManager: App.shared.networkManager)
        }
        addTokenServices.append(AddBep2TokenBlockchainService(networkManager: App.shared.networkManager))

        let service = AddTokenService(account: account, blockchainServices: addTokenServices, coinManager: App.shared.coinManager, walletManager: App.shared.walletManager)
        let viewModel = AddTokenViewModel(service: service)
        let viewController = AddTokenViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
