struct NftCollectionActivityModule {

    static func viewController(collectionUid: String) -> NftCollectionActivityViewController {
        let service = NftCollectionActivityService()
        let viewModel = NftCollectionActivityViewModel(service: service)
        return NftCollectionActivityViewController(viewModel: viewModel)
    }

}
