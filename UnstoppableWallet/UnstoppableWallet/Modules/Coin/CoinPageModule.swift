import MarketKit
import SwiftUI
import ThemeKit
import UIKit

struct CoinPageModule {
    static func view(fullCoin: FullCoin, apiTag: String) -> some View {
        let viewModel = CoinPageViewModelNew(fullCoin: fullCoin, favoritesManager: App.shared.favoritesManager)

        let overviewView = CoinOverviewModule.view(coinUid: fullCoin.coin.uid, apiTag: apiTag)
        let analyticsView = CoinAnalyticsModule.view(fullCoin: fullCoin, apiTag: apiTag)
        let marketsView = CoinMarketsModule.view(coin: fullCoin.coin)

        return CoinPageView(
            viewModel: viewModel,
            overviewView: { overviewView },
            analyticsView: { analyticsView.ignoresSafeArea(edges: .bottom) },
            marketsView: { marketsView.ignoresSafeArea(edges: .bottom) }
        )
    }

    static func viewController(coinUid: String, apiTag: String) -> UIViewController? {
        guard let fullCoin = try? App.shared.marketKit.fullCoins(coinUids: [coinUid]).first else {
            return nil
        }

        let service = CoinPageService(
            fullCoin: fullCoin,
            favoritesManager: App.shared.favoritesManager
        )

        let viewModel = CoinPageViewModel(service: service)

        let overviewController = CoinOverviewModule.viewController(coinUid: coinUid, apiTag: apiTag)
        let marketsController = CoinMarketsModule.view(coin: fullCoin.coin).toViewController()
        let analyticsController = CoinAnalyticsModule.viewController(fullCoin: fullCoin, apiTag: apiTag)
//        let tweetsController = CoinTweetsModule.viewController(fullCoin: fullCoin)

        let viewController = CoinPageViewController(
            viewModel: viewModel,
            overviewController: overviewController,
            analyticsController: analyticsController,
            marketsController: marketsController
        )

        return ThemeNavigationController(rootViewController: viewController)
    }
}

extension CoinPageModule {
    enum Tab: Int, CaseIterable {
        case overview
        case analytics
        case markets
//        case tweets

        var title: String {
            switch self {
            case .overview: return "coin_page.overview".localized
            case .analytics: return "coin_page.analytics".localized
            case .markets: return "coin_page.markets".localized
//            case .tweets: return "coin_page.tweets".localized
            }
        }
    }
}
