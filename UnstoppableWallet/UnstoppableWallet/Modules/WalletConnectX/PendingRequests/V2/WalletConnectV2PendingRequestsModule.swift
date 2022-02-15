import UIKit
import ThemeKit

struct WalletConnectV2PendingRequestsModule {

    static func viewController() -> UIViewController {
        let service = WalletConnectV2PendingRequestsService(
                sessionManager: App.shared.walletConnectV2SessionManager,
                accountManager: App.shared.accountManager
        )

        let viewModel = WalletConnectV2PendingRequestsViewModel(service: service)
        return WalletConnectV2PendingRequestsViewController(viewModel: viewModel)
    }

}
