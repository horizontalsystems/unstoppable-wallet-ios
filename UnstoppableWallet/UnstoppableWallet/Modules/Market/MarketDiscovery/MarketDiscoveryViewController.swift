import UIKit
import RxSwift
import ThemeKit
import SectionsTableView

class MarketDiscoveryViewController: MarketListViewController {
    private let marketViewModel: MarketViewModel
    private let viewModel: MarketDiscoveryViewModel
    private let disposeBag = DisposeBag()

    private let filterHeaderView = MarketDiscoveryFilterHeaderView()

    init(marketViewModel: MarketViewModel, listViewModel: MarketListViewModel, viewModel: MarketDiscoveryViewModel) {
        self.marketViewModel = marketViewModel
        self.viewModel = viewModel

        super.init(listViewModel: listViewModel, topPadding: MarketDiscoveryFilterHeaderView.headerHeight)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        filterHeaderView.onSelect = { [weak self] filterIndex in
            self?.viewModel.setFilter(at: filterIndex)
        }

        subscribe(disposeBag, viewModel.selectedFilterIndexDriver) { [weak self] index in
            self?.filterHeaderView.setSelected(index: index)
        }
        subscribe(disposeBag, marketViewModel.discoveryListTypeDriver) { [weak self] in self?.handle(listType: $0) }
    }

    private func handle(listType: MarketModule.ListType?) {
        guard let listType = listType else {
            return
        }

        listViewModel.set(listType: listType)
        viewModel.resetCategory()
    }

    override var topSections: [SectionProtocol] {
        [
            Section(
                    id: "filter",
                    headerState: .static(view: filterHeaderView, height: MarketDiscoveryFilterHeaderView.headerHeight)
            )
        ]
    }

}
