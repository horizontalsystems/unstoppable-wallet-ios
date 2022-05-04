import UIKit

protocol IMarketOverviewTopCoinsViewModel {
    var marketTop: MarketModule.MarketTop { get }
    var listType: MarketOverviewTopCoinsService.ListType { get }
}

class MarketOverviewTopCoinsDataSource: BaseMarketOverviewTopListDataSource {
    private let topCoinsViewModel: IMarketOverviewTopCoinsViewModel

    init(viewModel: IMarketOverviewTopCoinsViewModel & IBaseMarketOverviewTopListViewModel) {
        topCoinsViewModel = viewModel

        super.init(viewModel: viewModel)
    }

    override func didTapSeeAll() {
        let module = MarketTopModule.viewController(
                marketTop: topCoinsViewModel.marketTop,
                sortingField: topCoinsViewModel.listType.sortingField,
                marketField: topCoinsViewModel.listType.marketField
        )
        parentNavigationController?.present(module, animated: true)
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
        if let uid = listViewItem.uid, let module = CoinPageModule.viewController(coinUid: uid) {
            parentNavigationController?.present(module, animated: true)
        }
    }

}
