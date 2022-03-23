struct NftCollectionActivityModule {

    static func viewController(collection: NftCollection) -> NftCollectionActivityViewController {
        let service = NftCollectionActivityService()
        let viewModel = NftCollectionActivityViewModel(service: service)
        return NftCollectionActivityViewController(viewModel: viewModel)
    }

}
