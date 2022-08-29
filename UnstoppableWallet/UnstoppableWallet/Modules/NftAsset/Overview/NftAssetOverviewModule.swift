import UIKit

struct NftAssetOverviewModule {

    static func viewController(providerCollectionUid: String, nftUid: NftUid, imageRatio: CGFloat) -> NftAssetOverviewViewController {
        let coinPriceService = WalletCoinPriceService(
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let service = NftAssetOverviewService(
                providerCollectionUid: providerCollectionUid,
                nftUid: nftUid,
                nftMetadataManager: App.shared.nftMetadataManager,
                marketKit: App.shared.marketKit,
                coinPriceService: coinPriceService
        )

        coinPriceService.delegate = service

        let viewModel = NftAssetOverviewViewModel(service: service)
        return NftAssetOverviewViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true), imageRatio: imageRatio)
    }

}
