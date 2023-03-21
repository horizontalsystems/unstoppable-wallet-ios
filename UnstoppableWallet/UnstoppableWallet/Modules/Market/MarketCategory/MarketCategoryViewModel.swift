class MarketCategoryViewModel {
    private let service: MarketCategoryService

    init(service: MarketCategoryService) {
        self.service = service
    }

}

extension MarketCategoryViewModel {

    var title: String {
        service.category.name
    }

    var description: String? {
        service.category.descriptions[service.currentLanguage] ?? service.category.descriptions.first?.value
    }

    var imageUrl: String {
        service.category.imageUrl
    }

}
