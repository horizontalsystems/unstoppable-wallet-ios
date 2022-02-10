import UIKit


class WalletConnectXListModule {

    static func viewController() -> UIViewController {
        let uriHandler = WalletConnectUriHandler()
        let service = WalletConnectXListService(
                uriHandler: uriHandler,
                sessionManager: App.shared.walletConnectSessionManager,
                sessionManagerV2: App.shared.walletConnectV2SessionManager
        )
        let listViewModelV1 = WalletConnectV1XListViewModel(service: service)
        let listViewV1 = WalletConnectV1XListView(viewModel: listViewModelV1)

        let listViewModelV2 = WalletConnectV2XListViewModel(service: service)
        let listViewV2 = WalletConnectV2XListView(viewModel: listViewModelV2)

        let viewModel = WalletConnectXListViewModel(service: service)
        let viewController = WalletConnectXListViewController(listViewV1: listViewV1, listViewV2: listViewV2, viewModel: viewModel)
        listViewV1.sourceViewController = viewController
        listViewV2.sourceViewController = viewController

        return viewController
    }

}

extension WalletConnectXListService.Chain {

    var title: String {
        switch self {
        case .ethereum, .ropsten, .rinkeby, .kovan, .goerli: return "Ethereum"
        case .binanceSmartChain: return "BSC"
        }
    }

}
