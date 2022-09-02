import UIKit
import ThemeKit

class MarketOverviewNftCollectionsDataSource: BaseMarketOverviewTopListDataSource {
    private let viewModel: MarketOverviewNftCollectionsViewModel

    init(viewModel: MarketOverviewNftCollectionsViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel

        super.init(
                topListViewModel: viewModel,
                presentDelegate: presentDelegate,
                rightSelectorMode: .selector,
                imageName: "image_2_20",
                title: "market.top.top_collections".localized
        )
    }

    override func didTapSeeAll() {
        let module = MarketNftTopCollectionsModule.viewController(timePeriod: viewModel.timePeriod)
        presentDelegate?.present(viewController: module)
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
//        if let uid = listViewItem.uid, let module = NftCollectionModule.viewController(collectionUid: uid) {
//            presentDelegate?.present(viewController: ThemeNavigationController(rootViewController: module))
//        }
    }

}
