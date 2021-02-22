import UIKit

struct WalletConnectModule {

    static func start(session: WalletConnectSession? = nil, sourceViewController: UIViewController?) {
        let service = WalletConnectService(
                session: session,
                manager: App.shared.walletConnectManager,
                sessionManager: App.shared.walletConnectSessionManager,
                reachabilityManager: App.shared.reachabilityManager
        )
        let viewModel = WalletConnectViewModel(service: service)
        let view = WalletConnectView(viewModel: viewModel, sourceViewController: sourceViewController)

        sourceViewController?.present(view.initialViewController, animated: true)
    }

}
