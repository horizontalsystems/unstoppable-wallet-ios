import UIKit
import Chart
import LanguageKit
import ThemeKit
import MarketKit

struct CoinPageModule {

    static func viewController(coin: Coin) -> UIViewController? {
        guard let fullCoin = try? App.shared.coinManager.fullCoin(coinUid: coin.uid) else {
            return nil
        }

        let coinPageService = CoinPageService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                appConfigProvider: App.shared.appConfigProvider,
                currentLocale: LanguageManager.shared.currentLocale.languageCode ?? "en",
                fullCoin: fullCoin)

        let coinFavoriteService = CoinFavoriteService(manager: App.shared.favoritesManager, coinUid: fullCoin.coin.uid)

//        let priceAlertService = CoinPriceAlertService(
//                priceAlertManager: App.shared.priceAlertManager,
//                localStorage: App.shared.localStorage,
//                coinType: launchMode.coinType,
//                coinTitle: launchMode.coinTitle)

//        let coinChartService = CoinChartService(
//                rateManager: App.shared.rateManager,
//                chartTypeStorage: App.shared.localStorage,
//                currencyKit: App.shared.currencyKit,
//                coinType: launchMode.coinType)

        let chartFactory = CoinChartFactory(timelineHelper: TimelineHelper(), indicatorFactory: IndicatorFactory(), currentLocale: LanguageManager.shared.currentLocale)

        let coinPageViewModel = CoinPageViewModel(service: coinPageService)
        let favoriteViewModel = CoinFavoriteViewModel(service: coinFavoriteService)
//        let priceAlertViewModel = CoinPriceAlertViewModel(service: priceAlertService)
//        let coinChartViewModel = CoinChartViewModel(service: coinChartService, factory: chartFactory)

        let viewController = CoinPageViewController(
                viewModel: coinPageViewModel,
                favoriteViewModel: favoriteViewModel,
//                priceAlertViewModel: priceAlertViewModel,
//                chartViewModel: coinChartViewModel,
                configuration: ChartConfiguration.fullChart,
                markdownParser: CoinPageMarkdownParser(),
                urlManager: UrlManager(inApp: true)
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}
