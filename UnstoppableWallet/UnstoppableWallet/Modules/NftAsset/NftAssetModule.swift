import UIKit

struct NftAssetModule {

    static func viewController(collection: NftCollection, asset: NftAsset, imageRatio: CGFloat) -> UIViewController {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftAssetService(collection: collection, asset: asset, nftManager: App.shared.nftManager, coinPriceService: coinPriceService)

        coinPriceService.delegate = service

        let viewModel = NftAssetViewModel(service: service)
        return NftAssetViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true), imageRatio: imageRatio)
    }

}
