import UIKit
import LanguageKit
import MarketKit

struct NftAssetModule {

    static func viewController(providerCollectionUid: String, nftUid: NftUid) -> UIViewController {
        let overviewController = NftAssetOverviewModule.viewController(providerCollectionUid: providerCollectionUid, nftUid: nftUid)
        let activityController = NftActivityModule.viewController(eventListType: .asset(nftUid: nftUid), defaultEventType: nil)

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
