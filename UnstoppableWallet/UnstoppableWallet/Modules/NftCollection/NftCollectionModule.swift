import UIKit
import LanguageKit
import MarketKit
import ThemeKit

struct NftCollectionModule {

    static func viewController(blockchainType: BlockchainType, providerCollectionUid: String) -> UIViewController? {
        let service = NftCollectionService()
        let viewModel = NftCollectionViewModel(service: service)

        guard let overviewController = NftCollectionOverviewModule.viewController(blockchainType: blockchainType, providerCollectionUid: providerCollectionUid) else {
            return nil
        }

        let assetsController = NftCollectionAssetsModule.viewController(blockchainType: blockchainType, providerCollectionUid: providerCollectionUid)
        let activityController = NftActivityModule.viewController(eventListType: .collection(blockchainType: blockchainType, providerUid: providerCollectionUid))

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
