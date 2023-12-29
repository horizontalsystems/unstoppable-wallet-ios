import UIKit

class MarketOverviewTopPairsDataSource: BaseMarketOverviewTopListDataSource {
    private let viewModel: MarketOverviewTopPairsViewModel

    init(viewModel: MarketOverviewTopPairsViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel

        super.init(
            topListViewModel: viewModel,
            presentDelegate: presentDelegate,
            rightSelectorMode: .none,
            imageName: "pairs_24",
            title: "market.top.top_market_pairs".localized
        )
    }

    override func didTapSeeAll() {
        let module = MarketTopPairsModule.viewController()
        presentDelegate?.present(viewController: module)
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
        guard let uid = listViewItem.uid, let marketPair = viewModel.marketPair(uid: uid), let tradeUrl = marketPair.tradeUrl else {
            return
        }

        UrlManager.open(url: tradeUrl)
    }
}
