import MarketKit

class MarketCategoryViewModel {
    private let service: MarketCategoryService
    let viewItem: ViewItem

    init(service: MarketCategoryService) {
        self.service = service

        viewItem = ViewItem(
                name: service.name,
                description: service.categoryDescription,
                imageUrl: service.imageUrl,
                imageMode: service.imageMode
        )
    }

}

extension MarketCategoryViewModel {

    struct ViewItem {
        let name: String
        let description: String?
        let imageUrl: String
        let imageMode: ImageMode

        enum ImageMode {
            case large
            case small
        }
    }

}
