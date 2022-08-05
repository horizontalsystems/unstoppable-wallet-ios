import UIKit

class MarketOverviewTopPlatformsDataSource: BaseMarketOverviewTopListDataSource {
    private let viewModel: MarketOverviewTopPlatformsViewModel

    init(viewModel: MarketOverviewTopPlatformsViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel

        super.init(
                topListViewModel: viewModel,
                presentDelegate: presentDelegate,
                rightSelectorMode: .selector,
                imageName: "blocks_20",
                title: "market.top.top_platforms".localized
        )
    }

    override func didTapSeeAll() {
        let module = MarketTopPlatformsModule.viewController(timePeriod: viewModel.timePeriod)
        presentDelegate?.present(viewController: module)
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
        guard let uid = listViewItem.uid, let topPlatform = viewModel.topPlatform(uid: uid) else {
            return
        }

        presentDelegate?.present(viewController: TopPlatformModule.viewController(topPlatform: topPlatform))
    }

}
