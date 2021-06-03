import UIKit

struct EvmNetworkModule {

    static func viewController(blockchain: Blockchain, account: Account) -> UIViewController {
        let service = EvmNetworkService(blockchain: blockchain, account: account, evmNetworkManager: App.shared.evmNetworkManager, accountSettingManager: App.shared.accountSettingManager)
        let viewModel = EvmNetworkViewModel(service: service)
        return EvmNetworkViewController(viewModel: viewModel)
    }

}

extension EvmNetworkModule {

    enum Blockchain {
        case ethereum
        case binanceSmartChain
    }

}
