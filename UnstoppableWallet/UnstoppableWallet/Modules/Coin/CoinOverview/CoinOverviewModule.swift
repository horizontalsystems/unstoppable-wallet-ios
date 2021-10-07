import MarketKit
import LanguageKit
import Chart

struct CoinOverviewModule {

    static func viewController(fullCoin: FullCoin) -> CoinOverviewViewController {
        let service = CoinOverviewService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                appConfigProvider: App.shared.appConfigProvider,
                currentLocale: LanguageManager.shared.currentLocale.languageCode ?? "en",
                fullCoin: fullCoin
        )

        let coinChartService = CoinChartService(
                marketKit: App.shared.marketKit,
                chartTypeStorage: App.shared.localStorage,
                currencyKit: App.shared.currencyKit,
                coinUid: fullCoin.coin.uid)

        let chartFactory = CoinChartFactory(timelineHelper: TimelineHelper(), indicatorFactory: IndicatorFactory(), currentLocale: LanguageManager.shared.currentLocale)

        let coinPageOverviewViewModel = CoinOverviewViewModel(service: service)
        let coinChartViewModel = CoinChartViewModel(service: coinChartService, factory: chartFactory)

        return CoinOverviewViewController(
                viewModel: coinPageOverviewViewModel,
                chartViewModel: coinChartViewModel,
                configuration: ChartConfiguration.fullChart,
                markdownParser: CoinPageMarkdownParser(),
                urlManager: UrlManager(inApp: true)
        )
    }

}
