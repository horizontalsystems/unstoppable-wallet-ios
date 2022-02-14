import MarketKit

class MarketCategoryViewModel {
    private let service: MarketCategoryService
    let viewItem: ViewItem

    init(service: MarketCategoryService) {
        self.service = service

        viewItem = ViewItem(
                name: service.category.name,
                description: service.categoryDescription,
                imageUrl: service.category.imageUrl
        )
    }

}

extension MarketCategoryViewModel {

    struct ViewItem {
        let name: String
        let description: String?
        let imageUrl: String
    }

}
