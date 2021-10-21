import UIKit
import LanguageKit
import ThemeKit
import MarketKit

struct CoinPageModule {

    static func viewController(coinUid: String) -> UIViewController? {
        guard let fullCoin = try? App.shared.coinManager.fullCoin(coinUid: coinUid) else {
            return nil
        }

        let service = CoinPageService(fullCoin: fullCoin, favoritesManager: App.shared.favoritesManager)
        let viewModel = CoinPageViewModel(service: service)

        let overviewController = CoinOverviewModule.viewController(fullCoin: fullCoin)
        let marketsController = CoinMarketsModule.viewController(coin: fullCoin.coin)
        let detailsController = CoinOverviewModule.viewController(fullCoin: fullCoin)
        let tweetsController = CoinOverviewModule.viewController(fullCoin: fullCoin)

        let viewController = CoinPageViewController(
                viewModel: viewModel,
                overviewController: overviewController,
                marketsController: marketsController,
                detailsController: detailsController,
                tweetsController: tweetsController
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension CoinPageModule {

    enum Tab: Int, CaseIterable {
        case overview
        case markets
        case details
        case tweets

        var title: String {
            switch self {
            case .overview: return "coin_page.tab.overview".localized
            case .markets: return "coin_page.tab.markets".localized
            case .details: return "coin_page.tab.details".localized
            case .tweets: return "coin_page.tab.tweets".localized
            }
        }
    }

}
