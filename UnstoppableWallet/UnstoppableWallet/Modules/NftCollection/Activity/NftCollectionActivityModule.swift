struct NftCollectionActivityModule {

    static func viewController(collection: NftCollection) -> NftCollectionActivityViewController {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftCollectionActivityService(collection: collection, provider: App.shared.hsNftProvider, coinPriceService: coinPriceService)
        let viewModel = NftCollectionActivityViewModel(service: service)
        return NftCollectionActivityViewController(viewModel: viewModel)
    }

}
