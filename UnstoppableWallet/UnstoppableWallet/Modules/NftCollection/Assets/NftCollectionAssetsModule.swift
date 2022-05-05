struct NftCollectionAssetsModule {

    static func viewController(collectionUid: String) -> NftCollectionAssetsViewController {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftCollectionAssetsService(collectionUid: collectionUid, provider: App.shared.hsNftProvider, coinPriceService: coinPriceService)
        let viewModel = NftCollectionAssetsViewModel(service: service)
        return NftCollectionAssetsViewController(viewModel: viewModel)
    }

}
