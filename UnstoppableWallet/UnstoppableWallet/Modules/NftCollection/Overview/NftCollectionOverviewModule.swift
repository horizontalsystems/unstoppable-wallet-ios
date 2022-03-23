struct NftCollectionOverviewModule {

    static func viewController(collection: NftCollection) -> NftCollectionOverviewViewController {
        let service = NftCollectionOverviewService(collection: collection, provider: App.shared.hsNftProvider)
        let viewModel = NftCollectionOverviewViewModel(service: service)
        return NftCollectionOverviewViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
