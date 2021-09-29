import Foundation

struct MarketOverviewModule {
    static let overviewSectionItemCount = 5

    static func viewController(marketViewModel: MarketViewModel) -> MarketOverviewViewControllerNew {
        let postService = MarketPostService(postManager: App.shared.rateManager)

        let topGainersService = MarketOverviewServiceNew(overviewType: .gainers(count: overviewSectionItemCount), currencyKit: App.shared.currencyKit, appManager: App.shared.appManager, rateManager: App.shared.rateManager)
        let topGainersViewModel = MarketOverviewViewModelNew(service: topGainersService)

        let topLosersService = MarketOverviewServiceNew(overviewType: .losers(count: overviewSectionItemCount), currencyKit: App.shared.currencyKit, appManager: App.shared.appManager, rateManager: App.shared.rateManager)
        let topLosersViewModel = MarketOverviewViewModelNew(service: topLosersService)

        return MarketOverviewViewControllerNew(marketViewModel: marketViewModel, topGainersViewModel: topGainersViewModel, topLosersViewModel: topLosersViewModel, urlManager: UrlManager(inApp: true))
    }

}
