import UIKit
import LanguageKit
import ThemeKit
import MarketKit

struct NftCollectionModule {

    static func viewController(collectionUid: String) -> UIViewController {
        let service = NftCollectionService()
        let viewModel = NftCollectionViewModel(service: service)

        let overviewController = NftCollectionOverviewModule.viewController(collectionUid: collectionUid)
        let marketsController = NftCollectionAssetsModule.viewController(collectionUid: collectionUid)
        let detailsController = NftCollectionActivityModule.viewController(collectionUid: collectionUid)

        let viewController = NftCollectionViewController(
                viewModel: viewModel,
                overviewController: overviewController,
                marketsController: marketsController,
                detailsController: detailsController
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension NftCollectionModule {

    enum Tab: Int, CaseIterable {
        case overview
        case items
        case activity

        var title: String {
            switch self {
            case .overview: return "nft_collection.tab.overview".localized
            case .items: return "nft_collection.tab.items".localized
            case .activity: return "nft_collection.tab.activity".localized
            }
        }
    }

}
