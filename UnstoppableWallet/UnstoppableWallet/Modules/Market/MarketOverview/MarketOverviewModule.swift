import Foundation

struct MarketOverviewModule {
    static let overviewSectionItemCount = 5

    static func viewController(marketViewModel: MarketViewModel) -> MarketOverviewViewControllerNew {
        let topGainersService = MarketOverviewServiceNew(overviewType: .gainers(count: overviewSectionItemCount), currencyKit: App.shared.currencyKit, appManager: App.shared.appManager, marketKit: App.shared.marketKit)
        let topGainersViewModel = MarketOverviewViewModelNew(service: topGainersService)

        let topLosersService = MarketOverviewServiceNew(overviewType: .losers(count: overviewSectionItemCount), currencyKit: App.shared.currencyKit, appManager: App.shared.appManager, marketKit: App.shared.marketKit)
        let topLosersViewModel = MarketOverviewViewModelNew(service: topLosersService)

        return MarketOverviewViewControllerNew(marketViewModel: marketViewModel, topGainersViewModel: topGainersViewModel, topLosersViewModel: topLosersViewModel, urlManager: UrlManager(inApp: true))
    }

}
