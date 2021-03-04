struct MarketAdvancedSearchResultModule {

    static func viewController(service: MarketAdvancedSearchService) -> MarketAdvancedSearchResultViewController {
        let listService = MarketListService(currencyKit: App.shared.currencyKit, fetcher: service)
        let listViewModel = MarketListViewModel(service: listService)

        return MarketAdvancedSearchResultViewController(listViewModel: listViewModel)
    }

}
