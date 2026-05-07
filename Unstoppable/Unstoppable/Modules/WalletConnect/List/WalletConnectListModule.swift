import SwiftUI
import UIKit

enum WalletConnectListModule {
    static func viewController() -> UIViewController {
        let service = WalletConnectListService(
            sessionManager: Core.shared.walletConnectSessionManager,
            evmBlockchainManager: Core.shared.evmBlockchainManager
        )

        let viewModel = WalletConnectListViewModel(service: service, eventHandler: Core.shared.appEventHandler)
        let viewController = WalletConnectListViewController(viewModel: viewModel)

        return viewController
    }
}

struct WalletConnectListView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context _: Context) -> UIViewController {
        WalletConnectListModule.viewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
