struct NftCollectionAssetsModule {

    static func viewController(collectionUid: String) -> NftCollectionAssetsViewController {
        let service = NftCollectionAssetsService(collectionUid: collectionUid, provider: App.shared.hsNftProvider)
        let viewModel = NftCollectionAssetsViewModel(service: service)
        return NftCollectionAssetsViewController(viewModel: viewModel)
    }

}
