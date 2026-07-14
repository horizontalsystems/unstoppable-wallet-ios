import SwiftUI
import UIKit

enum WalletConnectListModule {
    static func viewController() -> UIViewController? {
        guard let sessionManager = Core.shared.walletConnectSessionManager else {
            return nil
        }

        let service = WalletConnectListService(
            sessionManager: sessionManager,
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
        WalletConnectListModule.viewController() ?? ErrorViewController(text: AppError.unknownError.localizedDescription)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
