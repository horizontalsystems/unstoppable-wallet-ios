import MarketKit
import LanguageKit
import Chart

struct CoinOverviewModule {

    static func viewController(coinUid: String) -> CoinOverviewViewController {
        let service = CoinOverviewService(
                coinUid: coinUid,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                languageManager: LanguageManager.shared,
                appConfigProvider: App.shared.appConfigProvider,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager
        )

        let repository = ChartIndicatorsRepository(localStorage: App.shared.localStorage)
        let chartService = CoinChartService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                indicatorRepository: repository,
                coinUid: coinUid
        )
        let router = ChartIndicatorRouter(repository: repository, fetcher: chartService)

        let viewModel = CoinOverviewViewModel(service: service)

        let chartFactory = CoinChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = CoinChartViewModel(service: chartService, factory: chartFactory)

        return CoinOverviewViewController(
                viewModel: viewModel,
                chartViewModel: chartViewModel,
                chartRouter: router,
                markdownParser: CoinPageMarkdownParser(),
                urlManager: UrlManager(inApp: true)
        )
    }

}
