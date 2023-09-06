import UIKit
import ThemeKit

struct WalletConnectPairingModule {

    static func viewController() -> UIViewController {
        let service = WalletConnectPairingService(sessionManager: App.shared.walletConnectSessionManager)

        let viewModel = WalletConnectPairingViewModel(service: service)
        return WalletConnectPairingViewController(viewModel: viewModel)
    }

}
