import MarketKit
import SwiftUI
import ThemeKit
import UIKit

enum CoinMajorHoldersModule {
    static func viewController(coin: Coin, blockchain: Blockchain) -> UIViewController {
        let service = CoinMajorHoldersService(coin: coin, blockchain: blockchain, marketKit: App.shared.marketKit, evmLabelManager: App.shared.evmLabelManager)
        let viewModel = CoinMajorHoldersViewModel(service: service)
        let urlManager = UrlManager(inApp: true)
        let viewController = CoinMajorHoldersViewController(viewModel: viewModel, urlManager: urlManager)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

struct CoinMajorHoldersView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let coin: Coin
    let blockchain: Blockchain

    func makeUIViewController(context _: Context) -> UIViewController {
        CoinMajorHoldersModule.viewController(coin: coin, blockchain: blockchain)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
