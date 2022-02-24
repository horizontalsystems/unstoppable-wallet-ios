import UIKit


class WalletConnectListModule {

    static func viewController() -> UIViewController {
        let service = WalletConnectListService(
                sessionManager: App.shared.walletConnectSessionManager,
                sessionManagerV2: App.shared.walletConnectV2SessionManager,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                evmChainParser: WalletConnectEvmChainParser()
        )
        let listViewModelV1 = WalletConnectV1ListViewModel(service: service)
        let listViewV1 = WalletConnectV1ListView(viewModel: listViewModelV1)

        let listViewModelV2 = WalletConnectV2ListViewModel(service: service)
        let listViewV2 = WalletConnectV2ListView(viewModel: listViewModelV2)

        let viewModel = WalletConnectListViewModel(service: service)
        let viewController = WalletConnectListViewController(listViewV1: listViewV1, listViewV2: listViewV2, viewModel: viewModel)
        listViewV1.sourceViewController = viewController
        listViewV2.sourceViewController = viewController

        return viewController
    }

}
