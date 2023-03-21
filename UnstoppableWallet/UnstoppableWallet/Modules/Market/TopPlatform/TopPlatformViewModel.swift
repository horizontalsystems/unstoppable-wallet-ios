class TopPlatformViewModel {
    private let service: TopPlatformService

    init(service: TopPlatformService) {
        self.service = service
    }

}

extension TopPlatformViewModel: IMarketFilteredListViewModel {

    var headerViewItem: MarketModule.HeaderViewItem {
        let topPlatform = service.topPlatform

        return MarketModule.HeaderViewItem(
                name: "top_platform.title".localized(topPlatform.blockchain.name),
                description: "top_platform.description".localized(topPlatform.blockchain.name),
                imageUrl: topPlatform.blockchain.type.imageUrl,
                imageMode: .small
        )
    }

}
