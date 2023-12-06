import ThemeKit
import UIKit

enum WalletConnectPairingModule {
    static func viewController() -> UIViewController {
        let service = WalletConnectPairingService(sessionManager: App.shared.walletConnectSessionManager)

        let viewModel = WalletConnectPairingViewModel(service: service)
        return WalletConnectPairingViewController(viewModel: viewModel)
    }
}
