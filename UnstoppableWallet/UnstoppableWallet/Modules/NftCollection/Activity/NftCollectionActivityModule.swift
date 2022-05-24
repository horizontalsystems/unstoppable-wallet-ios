struct NftCollectionActivityModule {

    static func viewController(collectionUid: String) -> NftCollectionActivityViewController {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftCollectionActivityService(collectionUid: collectionUid, marketKit: App.shared.marketKit, coinPriceService: coinPriceService)
        let viewModel = NftCollectionActivityViewModel(service: service)
        return NftCollectionActivityViewController(viewModel: viewModel)
    }

}
