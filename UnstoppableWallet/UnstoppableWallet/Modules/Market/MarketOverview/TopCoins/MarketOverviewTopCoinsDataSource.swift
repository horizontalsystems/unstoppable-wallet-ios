import UIKit

protocol IMarketOverviewTopCoinsViewModel {
    var marketTop: MarketModule.MarketTop { get }
    var listType: MarketOverviewTopCoinsService.ListType { get }
}

class MarketOverviewTopCoinsDataSource: BaseMarketOverviewTopListDataSource {
    private let topCoinsViewModel: IMarketOverviewTopCoinsViewModel

    init(viewModel: IMarketOverviewTopCoinsViewModel & IBaseMarketOverviewTopListViewModel, presentDelegate: IPresentDelegate) {
        topCoinsViewModel = viewModel

        super.init(viewModel: viewModel, presentDelegate: presentDelegate)
    }

    override func didTapSeeAll() {
        let module = MarketTopModule.viewController(
                marketTop: topCoinsViewModel.marketTop,
                sortingField: topCoinsViewModel.listType.sortingField,
                marketField: topCoinsViewModel.listType.marketField
        )
        presentDelegate.present(viewController: module)
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
        if let uid = listViewItem.uid, let module = CoinPageModule.viewController(coinUid: uid) {
            presentDelegate.present(viewController: module)
        }
    }

}
