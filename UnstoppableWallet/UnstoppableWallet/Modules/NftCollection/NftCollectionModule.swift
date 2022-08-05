import UIKit
import LanguageKit
import MarketKit
import ThemeKit

struct NftCollectionModule {

    static func viewController(collectionUid: String) -> UIViewController? {
        let service = NftCollectionService()
        let viewModel = NftCollectionViewModel(service: service)

        guard let overviewController = NftCollectionOverviewModule.viewController(collectionUid: collectionUid) else {
            return nil
        }

        let assetsController = NftCollectionAssetsModule.viewController(collectionUid: collectionUid)
        let activityController = NftActivityModule.viewController(eventListType: .collection(uid: collectionUid))

        return NftCollectionViewController(
                viewModel: viewModel,
                overviewController: overviewController,
                assetsController: assetsController,
                activityController: activityController
        )
    }

}

extension NftCollectionModule {

    enum Tab: Int, CaseIterable {
        case overview
        case assets
        case activity

        var title: String {
            switch self {
            case .overview: return "nft_collection.tab.overview".localized
            case .assets: return "nft_collection.tab.assets".localized
            case .activity: return "nft_collection.tab.activity".localized
            }
        }
    }

}
