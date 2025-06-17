import MarketKit

enum NftCollectionOverviewModule {
    static func viewController(blockchainType: BlockchainType, providerCollectionUid: String) -> NftCollectionOverviewViewController? {
        guard let baseToken = try? Core.shared.marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: .native)) else {
            return nil
        }

        let coinService = CoinService(
            token: baseToken,
            currencyManager: Core.shared.currencyManager,
            marketKit: Core.shared.marketKit
        )

        let service = NftCollectionOverviewService(
            blockchainType: blockchainType,
            providerCollectionUid: providerCollectionUid,
            nftMetadataManager: Core.shared.nftMetadataManager,
            marketKit: Core.shared.marketKit
        )

        let viewModel = NftCollectionOverviewViewModel(service: service, coinService: coinService)
        return NftCollectionOverviewViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }
}
