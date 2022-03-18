struct NftCollectionAssetsModule {

    static func viewController(collectionUid: String) -> NftCollectionAssetsViewController {
        let service = NftCollectionAssetsService()
        let viewModel = NftCollectionAssetsViewModel(service: service)
        return NftCollectionAssetsViewController(viewModel: viewModel)
    }

}
