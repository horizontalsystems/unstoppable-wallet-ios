struct NftCollectionOverviewModule {

    static func viewController(collectionUid: String) -> NftCollectionOverviewViewController {
        let service = NftCollectionOverviewService()
        let viewModel = NftCollectionOverviewViewModel(service: service)
        return NftCollectionOverviewViewController(viewModel: viewModel)
    }

}
