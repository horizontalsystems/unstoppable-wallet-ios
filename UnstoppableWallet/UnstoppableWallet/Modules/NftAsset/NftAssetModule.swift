import UIKit
import ThemeKit

struct NftAssetModule {

    static func viewController(collectionUid: String, tokenId: String, imageRatio: CGFloat) -> UIViewController? {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        guard let service = NftAssetService(collectionUid: collectionUid, tokenId: tokenId, nftManager: App.shared.nftManager, coinPriceService: coinPriceService) else {
            return nil
        }

        coinPriceService.delegate = service

        let viewModel = NftAssetViewModel(service: service)
        let viewController = NftAssetViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true), imageRatio: imageRatio)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
