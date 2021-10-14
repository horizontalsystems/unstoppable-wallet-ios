import MarketKit

struct MarketAdvancedSearchResultModule {

    static func viewController(marketInfos: [MarketInfo]) -> UIViewController {
        let service = MarketAdvancedSearchResultService(marketInfos: marketInfos, currencyKit: App.shared.currencyKit)
        let watchlistToggleService = MarketWatchlistToggleService(listService: service, favoritesManager: App.shared.favoritesManager)

        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, marketField: .price)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, listViewModel: listViewModel)

        return MarketAdvancedSearchResultViewController(listViewModel: listViewModel, headerViewModel: headerViewModel)
    }

}
