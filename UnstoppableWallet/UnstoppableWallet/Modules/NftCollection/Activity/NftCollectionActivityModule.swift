struct NftCollectionActivityModule {

    static func viewController(collectionUid: String) -> NftCollectionActivityViewController {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftCollectionActivityService(collectionUid: collectionUid, provider: App.shared.hsNftProvider, coinPriceService: coinPriceService)
        let viewModel = NftCollectionActivityViewModel(service: service)
        return NftCollectionActivityViewController(viewModel: viewModel)
    }

}
