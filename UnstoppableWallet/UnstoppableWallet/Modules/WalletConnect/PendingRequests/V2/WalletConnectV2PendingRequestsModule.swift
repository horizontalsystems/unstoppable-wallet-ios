import UIKit
import ThemeKit

struct WalletConnectV2PendingRequestsModule {

    static func viewController() -> UIViewController {
        let service = WalletConnectV2PendingRequestsService(
                sessionManager: App.shared.walletConnectV2SessionManager,
                accountManager: App.shared.accountManager,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                signService: App.shared.walletConnectV2SessionManager.service
        )

        let viewModel = WalletConnectV2PendingRequestsViewModel(service: service)
        return WalletConnectV2PendingRequestsViewController(viewModel: viewModel)
    }

}
