import UIKit
import ThemeKit

struct WalletConnectPendingRequestsModule {

    static func viewController() -> UIViewController {
        let service = WalletConnectPendingRequestsService(
                sessionManager: App.shared.walletConnectSessionManager,
                accountManager: App.shared.accountManager,
                requestHandler: App.shared.walletConnectRequestHandler,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                signService: App.shared.walletConnectSessionManager.service
        )

        let viewModel = WalletConnectPendingRequestsViewModel(service: service)
        return WalletConnectPendingRequestsViewController(
                viewModel: viewModel,
                requestViewFactory: App.shared.walletConnectRequestHandler
        )
    }

}
