import UIKit

class WalletConnectListModule {
    static func viewController() -> UIViewController {
        let service = WalletConnectListService(
            sessionManager: App.shared.walletConnectSessionManager,
            evmBlockchainManager: App.shared.evmBlockchainManager
        )

        let viewModel = WalletConnectListViewModel(service: service, eventHandler: App.shared.appEventHandler)
        let viewController = WalletConnectListViewController(viewModel: viewModel)

        return viewController
    }
}
