import MarketKit
import LanguageKit
import Chart

struct CoinOverviewModule {

    static func viewController(fullCoin: FullCoin) -> CoinOverviewViewController {
        let service = CoinOverviewService(
                fullCoin: fullCoin,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                languageManager: LanguageManager.shared,
                appConfigProvider: App.shared.appConfigProvider
        )

        let chartService = CoinChartService(
                marketKit: App.shared.marketKit,
                localStorage: App.shared.localStorage,
                currencyKit: App.shared.currencyKit,
                coinUid: fullCoin.coin.uid)

        let viewModel = CoinOverviewViewModel(service: service)

        let chartFactory = CoinChartFactory(timelineHelper: TimelineHelper(), indicatorFactory: IndicatorFactory(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = CoinChartViewModel(service: chartService, factory: chartFactory)

        return CoinOverviewViewController(
                viewModel: viewModel,
                chartViewModel: chartViewModel,
                configuration: ChartConfiguration.fullChart,
                markdownParser: CoinPageMarkdownParser(),
                urlManager: UrlManager(inApp: true)
        )
    }

}
