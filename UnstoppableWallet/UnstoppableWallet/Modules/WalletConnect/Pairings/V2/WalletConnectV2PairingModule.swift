import UIKit
import ThemeKit

struct WalletConnectV2PairingModule {

    static func viewController() -> UIViewController {
        let service = WalletConnectV2PairingService(sessionManager: App.shared.walletConnectV2SessionManager)

        let viewModel = WalletConnectV2PairingViewModel(service: service)
        return WalletConnectV2PairingViewController(viewModel: viewModel)
    }

}
