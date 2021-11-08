import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class MarketAdvancedSearchResultViewController: MarketListViewController {
    private let multiSortHeaderView: MarketMultiSortHeaderView

    override var viewController: UIViewController? { self }
    override var headerView: UITableViewHeaderFooterView? { multiSortHeaderView }
    override var refreshEnabled: Bool { false }

    init(listViewModel: IMarketListViewModel, headerViewModel: MarketMultiSortHeaderViewModel) {
        multiSortHeaderView = MarketMultiSortHeaderView(viewModel: headerViewModel)

        super.init(listViewModel: listViewModel)

        multiSortHeaderView.viewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "market.advanced_search_results.title".localized
    }

}
