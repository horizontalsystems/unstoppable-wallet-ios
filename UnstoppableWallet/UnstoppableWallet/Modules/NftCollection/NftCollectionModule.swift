import UIKit
import LanguageKit
import MarketKit

struct NftCollectionModule {

    static func viewController(collection: NftCollection) -> UIViewController {
        let service = NftCollectionService()
        let viewModel = NftCollectionViewModel(service: service)

        let overviewController = NftCollectionOverviewModule.viewController(collection: collection)
        let assetsController = NftCollectionAssetsModule.viewController(collection: collection)
        let activityController = NftCollectionActivityModule.viewController(collection: collection)

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
