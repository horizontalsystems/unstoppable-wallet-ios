import UIKit

struct WalletConnectModule {

    static func start(sourceViewController: UIViewController?) {
        let service = WalletConnectService(
                ethereumKitManager: App.shared.ethereumKitManager,
                sessionStore: App.shared.walletConnectSessionStore,
                reachabilityManager: App.shared.reachabilityManager
        )
        let viewModel = WalletConnectViewModel(service: service)
        let view = WalletConnectView(viewModel: viewModel, sourceViewController: sourceViewController)

        sourceViewController?.present(view.initialViewController, animated: true)
    }

}
