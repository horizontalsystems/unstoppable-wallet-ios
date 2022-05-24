import UIKit

struct NftAssetModule {

    static func viewController(collectionUid: String, contractAddress: String, tokenId: String, imageRatio: CGFloat) -> UIViewController {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftAssetService(collectionUid: collectionUid, contractAddress: contractAddress, tokenId: tokenId, marketKit: App.shared.marketKit, coinPriceService: coinPriceService)

        coinPriceService.delegate = service

        let viewModel = NftAssetViewModel(service: service)
        return NftAssetViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true), imageRatio: imageRatio)
    }

}
