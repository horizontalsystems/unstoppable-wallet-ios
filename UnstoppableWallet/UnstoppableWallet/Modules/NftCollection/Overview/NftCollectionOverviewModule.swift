import MarketKit

struct NftCollectionOverviewModule {

    static func viewController(blockchainType: BlockchainType, providerCollectionUid: String) -> NftCollectionOverviewViewController? {
        guard let baseToken = try? App.shared.marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: .native)) else {
            return nil
        }

        let coinService = CoinService(
                token: baseToken,
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let service = NftCollectionOverviewService(
                blockchainType: blockchainType,
                providerCollectionUid: providerCollectionUid,
                nftMetadataManager: App.shared.nftMetadataManager,
                marketKit: App.shared.marketKit
        )

        let viewModel = NftCollectionOverviewViewModel(service: service, coinService: coinService)
        return NftCollectionOverviewViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
