import MarketKit

struct NftCollectionOverviewModule {

    static func viewController(collectionUid: String) -> NftCollectionOverviewViewController? {
        guard let basePlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .ethereum) else {
            return nil
        }

        let coinService = CoinService(
                platformCoin: basePlatformCoin,
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let service = NftCollectionOverviewService(collectionUid: collectionUid, marketKit: App.shared.marketKit)
        let viewModel = NftCollectionOverviewViewModel(service: service, coinService: coinService)
        return NftCollectionOverviewViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
