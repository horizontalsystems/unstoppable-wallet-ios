struct NftCollectionAssetsModule {

    static func viewController(collection: NftCollection) -> NftCollectionAssetsViewController {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftCollectionAssetsService(collection: collection, provider: App.shared.hsNftProvider, coinPriceService: coinPriceService)
        let viewModel = NftCollectionAssetsViewModel(service: service)
        return NftCollectionAssetsViewController(viewModel: viewModel)
    }

}
