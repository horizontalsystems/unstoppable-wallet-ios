import MarketKit

enum NftCollectionAssetsModule {
    static func viewController(blockchainType: BlockchainType, providerCollectionUid: String) -> NftCollectionAssetsViewController {
        let coinPriceService = WalletCoinPriceService(tag: "nft-collection-assets", currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)
        let service = NftCollectionAssetsService(blockchainType: blockchainType, providerCollectionUid: providerCollectionUid, nftMetadataManager: App.shared.nftMetadataManager, coinPriceService: coinPriceService)
        let viewModel = NftCollectionAssetsViewModel(service: service)
        return NftCollectionAssetsViewController(viewModel: viewModel)
    }
}
