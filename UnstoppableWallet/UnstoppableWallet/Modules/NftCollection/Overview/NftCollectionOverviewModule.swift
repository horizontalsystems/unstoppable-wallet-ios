import MarketKit

struct NftCollectionOverviewModule {

    static func viewController(collectionUid: String) -> NftCollectionOverviewViewController? {
        guard let ethereumToken = try? App.shared.marketKit.token(query: TokenQuery(blockchainType: .ethereum, tokenType: .native)) else {
            return nil
        }

        let coinService = CoinService(
                token: ethereumToken,
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let service = NftCollectionOverviewService(collectionUid: collectionUid, marketKit: App.shared.marketKit)
        let viewModel = NftCollectionOverviewViewModel(service: service, coinService: coinService)
        return NftCollectionOverviewViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
