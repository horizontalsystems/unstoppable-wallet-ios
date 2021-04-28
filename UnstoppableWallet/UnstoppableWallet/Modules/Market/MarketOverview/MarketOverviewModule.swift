import Foundation

struct MarketOverviewModule {

    static func viewController(marketViewModel: MarketViewModel) -> MarketOverviewViewController {
        let overviewService = MarketOverviewService(currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager)
        let overviewViewModel = MarketOverviewViewModel(service: overviewService)

        let postService = MarketPostService(postManager: App.shared.rateManager)
        let postViewModel = MarketPostViewModel(service: postService)

        return MarketOverviewViewController(marketViewModel: marketViewModel, postViewModel: postViewModel, overviewViewModel: overviewViewModel, urlManager: UrlManager(inApp: true))
    }

}
