import UIKit

struct WalletConnectModule {

    static func start(sourceViewController: UIViewController?) {
        Self.internalStart(sourceViewController: sourceViewController)
    }

    static func start(session: WalletConnectSession, sourceViewController: UIViewController?) {
        Self.internalStart(session: session, sourceViewController: sourceViewController)
    }

    static func start(uri: String, sourceViewController: UIViewController?) {
        Self.internalStart(uri: uri, sourceViewController: sourceViewController)
    }

    private static func internalStart(session: WalletConnectSession? = nil, uri: String? = nil, sourceViewController: UIViewController?) {
        let service = WalletConnectService(
                session: session,
                uri: uri,
                manager: App.shared.walletConnectManager,
                sessionManager: App.shared.walletConnectSessionManager,
                reachabilityManager: App.shared.reachabilityManager
        )
        let viewModel = WalletConnectViewModel(service: service)
        let view = WalletConnectView(viewModel: viewModel, sourceViewController: sourceViewController)

        sourceViewController?.present(view.initialViewController, animated: true)
    }

}
