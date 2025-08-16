import MarketKit
import SwiftUI

import UIKit

enum MoneroNetworkModule {
    static func viewController(blockchain: Blockchain) -> UIViewController {
        let service = MoneroNetworkService(blockchain: blockchain, moneroNodeManager: Core.shared.moneroNodeManager)
        let viewModel = MoneroNetworkViewModel(service: service)
        let viewController = MoneroNetworkViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

struct MoneroNetworkView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let blockchain: Blockchain

    func makeUIViewController(context _: Context) -> UIViewController {
        MoneroNetworkModule.viewController(blockchain: blockchain)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
