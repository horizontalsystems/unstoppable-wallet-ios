import MarketKit
import SwiftUI
import UIKit

struct CoinMarketsModule {
    static func view(coin: Coin) -> some View {
        CoinMarketsView(coin: coin)
    }

    static func viewController(coin: Coin) -> CoinMarketsViewController {
        let service = CoinMarketsService(
            coin: coin,
            marketKit: App.shared.marketKit,
            currencyKit: App.shared.currencyKit
        )

        let viewModel = CoinMarketsViewModel(service: service)
        let headerViewModel = MarketSingleSortHeaderViewModel(service: service, decorator: viewModel)

        return CoinMarketsViewController(viewModel: viewModel, headerViewModel: headerViewModel, urlManager: UrlManager(inApp: false))
    }
}

struct CoinMarketsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let coin: Coin

    func makeUIViewController(context _: Context) -> UIViewController {
        CoinMarketsModule.viewController(coin: coin)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
