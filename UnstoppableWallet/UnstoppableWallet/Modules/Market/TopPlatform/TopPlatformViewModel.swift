class TopPlatformViewModel {
    private let service: TopPlatformService

    init(service: TopPlatformService) {
        self.service = service
    }

}

extension TopPlatformViewModel {

    var title: String {
        "top_platform.title".localized(service.topPlatform.blockchain.name)
    }

    var description: String {
        "top_platform.description".localized(service.topPlatform.blockchain.name)
    }

    var imageUrl: String {
        service.topPlatform.blockchain.type.imageUrl
    }

}
