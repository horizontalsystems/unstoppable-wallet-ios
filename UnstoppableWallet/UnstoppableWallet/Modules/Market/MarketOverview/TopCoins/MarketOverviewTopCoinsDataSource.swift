import UIKit

class MarketOverviewTopCoinsDataSource: BaseMarketOverviewTopListDataSource {
    private let viewModel: MarketOverviewTopCoinsViewModel

    init(viewModel: MarketOverviewTopCoinsViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel

        let imageName: String
        let title: String

        switch viewModel.listType {
        case .topGainers:
            imageName = "circle_up_20"
            title = "market.top.section.header.top_gainers".localized
        case .topLosers:
            imageName = "circle_down_20"
            title = "market.top.section.header.top_losers".localized
        }

        super.init(
                topListViewModel: viewModel,
                presentDelegate: presentDelegate,
                rightSelectorMode: .selector,
                imageName: imageName,
                title: title
        )
    }

    override func didTapSeeAll() {
        let module = MarketTopModule.viewController(
                marketTop: viewModel.marketTop,
                sortingField: viewModel.listType.sortingField,
                marketField: viewModel.listType.marketField
        )
        presentDelegate?.present(viewController: module)
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
        if let uid = listViewItem.uid, let module = CoinPageModule.viewController(coinUid: uid) {
            presentDelegate?.present(viewController: module)
        }
    }

}
