import UIKit

struct EvmNetworkModule {

    static func viewController(blockchain: EvmBlockchain, account: Account) -> UIViewController {
        let service = EvmNetworkService(blockchain: blockchain, account: account, evmSyncSourceManager: App.shared.evmSyncSourceManager)
        let viewModel = EvmNetworkViewModel(service: service)
        return EvmNetworkViewController(viewModel: viewModel)
    }

}
