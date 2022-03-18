import UIKit
import LanguageKit
import ThemeKit
import MarketKit

struct NftCollectionModule {

    static func viewController(collectionUid: String) -> UIViewController {
        let service = NftCollectionService()
        let viewModel = NftCollectionViewModel(service: service)

        let overviewController = NftCollectionOverviewModule.viewController(collectionUid: collectionUid)
        let assetsController = NftCollectionAssetsModule.viewController(collectionUid: collectionUid)
        let activityController = NftCollectionActivityModule.viewController(collectionUid: collectionUid)

        let viewController = NftCollectionViewController(
                viewModel: viewModel,
                overviewController: overviewController,
                assetsController: assetsController,
                activityController: activityController
        )

        return ThemeNavigationController(rootViewController: viewController)
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
