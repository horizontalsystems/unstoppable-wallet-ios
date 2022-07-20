import UIKit

struct NftAssetOverviewModule {

    static func viewController(collectionUid: String, contractAddress: String, tokenId: String, imageRatio: CGFloat) -> NftAssetOverviewViewController {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftAssetOverviewService(collectionUid: collectionUid, contractAddress: contractAddress, tokenId: tokenId, marketKit: App.shared.marketKit, coinPriceService: coinPriceService)

        coinPriceService.delegate = service

        let viewModel = NftAssetOverviewViewModel(service: service)
        return NftAssetOverviewViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true), imageRatio: imageRatio)
    }

}
