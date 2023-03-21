class MarketCategoryViewModel {
    private let service: MarketCategoryService

    init(service: MarketCategoryService) {
        self.service = service
    }

}

extension MarketCategoryViewModel: IMarketFilteredListViewModel {

    var headerViewItem: MarketModule.HeaderViewItem {
        let category = service.category

        return MarketModule.HeaderViewItem(
                name: category.name,
                description: category.descriptions[service.currentLanguage] ?? category.descriptions.first?.value,
                imageUrl: category.imageUrl,
                imageMode: .large
        )
    }

}
