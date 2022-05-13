import UIKit

class MarketOverviewTopPlatformsDataSource: BaseMarketOverviewTopListDataSource {

    override func didTapSeeAll() {
        print("didTapSeeAll")
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
        print("onSelect(listViewItem")
    }

}
