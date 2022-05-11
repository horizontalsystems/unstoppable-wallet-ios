import UIKit
import ThemeKit

class MarketOverviewNftCollectionsDataSource: BaseMarketOverviewTopListDataSource {

    override func didTapSeeAll() {
        let module = MarketNftTopCollectionsModule.viewController()
        presentDelegate.present(viewController: module)
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
        if let uid = listViewItem.uid {
            let module = NftCollectionModule.viewController(collectionUid: uid)
            presentDelegate.present(viewController: ThemeNavigationController(rootViewController: module))
        }
    }

}
