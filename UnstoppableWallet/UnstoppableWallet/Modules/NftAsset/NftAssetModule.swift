import UIKit
import ThemeKit

struct NftAssetModule {

    static func viewController(collectionSlug: String, tokenId: String) -> UIViewController? {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        guard let service = NftAssetService(collectionSlug: collectionSlug, tokenId: tokenId, nftManager: App.shared.nftManager, coinPriceService: coinPriceService) else {
            return nil
        }

        coinPriceService.delegate = service

        let viewModel = NftAssetViewModel(service: service)
        let viewController = NftAssetViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
