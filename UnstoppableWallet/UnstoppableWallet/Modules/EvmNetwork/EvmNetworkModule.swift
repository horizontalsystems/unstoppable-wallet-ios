import MarketKit
import SwiftUI
import ThemeKit
import UIKit

struct EvmNetworkModule {
    static func viewController(blockchain: Blockchain) -> UIViewController {
        let service = EvmNetworkService(blockchain: blockchain, evmSyncSourceManager: App.shared.evmSyncSourceManager)
        let viewModel = EvmNetworkViewModel(service: service)
        let viewController = EvmNetworkViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

struct EvmNetworkView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let blockchain: Blockchain

    func makeUIViewController(context _: Context) -> UIViewController {
        EvmNetworkModule.viewController(blockchain: blockchain)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
