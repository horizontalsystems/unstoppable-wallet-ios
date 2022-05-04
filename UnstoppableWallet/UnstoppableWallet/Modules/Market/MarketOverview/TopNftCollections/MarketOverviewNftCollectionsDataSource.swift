import UIKit

protocol IMarketOverviewNftCollectionsViewModel {
    func collection(uid: String) -> NftCollection?
}

class MarketOverviewNftCollectionsDataSource: BaseMarketOverviewTopListDataSource {
    private let nftCollectionsViewModel: IMarketOverviewNftCollectionsViewModel

    init(viewModel: IMarketOverviewNftCollectionsViewModel & IBaseMarketOverviewTopListViewModel) {
        nftCollectionsViewModel = viewModel

        super.init(viewModel: viewModel)
    }

    override func didTapSeeAll() {
        let module = MarketNftTopCollectionsModule.viewController()
        parentNavigationController?.present(module, animated: true)
    }

    override func onSelect(listViewItem: MarketModule.ListViewItem) {
        if let uid = listViewItem.uid, let collection = nftCollectionsViewModel.collection(uid: uid) {
            let module = NftCollectionModule.viewController(collection: collection)
            parentNavigationController?.pushViewController(module, animated: true)
        }
    }

}
