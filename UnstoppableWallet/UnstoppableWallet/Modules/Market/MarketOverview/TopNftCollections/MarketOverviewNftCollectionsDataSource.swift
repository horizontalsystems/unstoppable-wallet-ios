import UIKit
import ThemeKit

class MarketOverviewNftCollectionsDataSource: BaseMarketOverviewTopListDataSource {

    override func didTapSeeAll() {
        let module = MarketNftTopCollectionsModule.viewController()
        parentNavigationController?.present(module, animated: true)
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
        if let uid = listViewItem.uid {
            let module = NftCollectionModule.viewController(collectionUid: uid)
            parentNavigationController?.present(ThemeNavigationController(rootViewController: module), animated: true)
        }
    }

}
