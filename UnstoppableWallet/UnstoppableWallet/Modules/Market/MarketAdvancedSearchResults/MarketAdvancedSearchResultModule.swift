import MarketKit

struct MarketAdvancedSearchResultModule {

    static func viewController(marketInfos: [MarketInfo], priceChangeType: MarketModule.PriceChangeType) -> UIViewController {
        let service = MarketAdvancedSearchResultService(marketInfos: marketInfos, currencyKit: App.shared.currencyKit, priceChangeType: priceChangeType)
        let watchlistToggleService = MarketWatchlistToggleService(listService: service, favoritesManager: App.shared.favoritesManager)

        let decorator = MarketListMarketFieldDecorator(service: service, marketField: .price)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, decorator: decorator)

        return MarketAdvancedSearchResultViewController(listViewModel: listViewModel, headerViewModel: headerViewModel)
    }

}
