import ThemeKit
import EthereumKit
import MarketKit

struct AddTokenModule {

    static func viewController() -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        var addTokenServices: [IAddTokenBlockchainService] = App.shared.evmBlockchainManager.allBlockchains.map {
            AddEvmTokenBlockchainService(blockchainType: $0.type, networkManager: App.shared.networkManager)
        }
        addTokenServices.append(AddBep2TokenBlockchainService(networkManager: App.shared.networkManager))

        let service = AddTokenService(account: account, blockchainServices: addTokenServices, marketKit: App.shared.marketKit, coinManager: App.shared.coinManager, walletManager: App.shared.walletManager)
        let viewModel = AddTokenViewModel(service: service)
        let viewController = AddTokenViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension AddTokenModule {

    struct CustomCoin {
        let tokenQuery: TokenQuery
        let name: String
        let code: String
        let decimals: Int
    }

}
