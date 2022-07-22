import UIKit
import LanguageKit
import MarketKit

struct NftAssetModule {

    static func viewController(collectionUid: String, contractAddress: String, tokenId: String, imageRatio: CGFloat) -> UIViewController {
        let overviewController = NftAssetOverviewModule.viewController(collectionUid: collectionUid, contractAddress: contractAddress, tokenId: tokenId, imageRatio: imageRatio)
        let activityController = NftActivityModule.viewController(eventListType: .asset(contractAddress: contractAddress, tokenId: tokenId), defaultEventType: nil)

        return NftAssetViewController(
                overviewController: overviewController,
                activityController: activityController
        )
    }

}

extension NftAssetModule {

    enum Tab: Int, CaseIterable {
        case overview
        case activity

        var title: String {
            switch self {
            case .overview: return "nft_asset.tab.overview".localized
            case .activity: return "nft_asset.tab.activity".localized
            }
        }
    }

}
