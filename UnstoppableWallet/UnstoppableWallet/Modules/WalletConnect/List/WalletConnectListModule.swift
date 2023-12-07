import SwiftUI
import UIKit

enum WalletConnectListModule {
    static func viewController() -> UIViewController {
        let service = WalletConnectListService(
            sessionManager: App.shared.walletConnectSessionManager,
            evmBlockchainManager: App.shared.evmBlockchainManager
        )

        let viewModel = WalletConnectListViewModel(service: service, eventHandler: App.shared.appEventHandler)
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
