struct NftCollectionOverviewModule {

    static func viewController(collectionUid: String) -> NftCollectionOverviewViewController {
        let service = NftCollectionOverviewService(collectionUid: collectionUid, marketKit: App.shared.marketKit)
        let viewModel = NftCollectionOverviewViewModel(service: service)
        return NftCollectionOverviewViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
