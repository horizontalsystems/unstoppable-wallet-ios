import UIKit

class MarketOverviewTopPlatformsDataSource: BaseMarketOverviewTopListDataSource {

    override func didTapSeeAll() {
        let module = MarketTopPlatformsModule.viewController()
        presentDelegate.present(viewController: module)
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
        print("onSelect(listViewItem")
    }

}
