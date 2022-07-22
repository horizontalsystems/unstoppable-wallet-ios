import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class MarketWatchlistViewController: MarketListViewController {
    weak var parentNavigationController: UINavigationController?

    private let viewModel: MarketWatchlistViewModel

    private let multiSortHeaderView: MarketMultiSortHeaderView
    private let placeholderView = PlaceholderView()

    override var viewController: UIViewController? { parentNavigationController }
    override var headerView: UITableViewHeaderFooterView? { multiSortHeaderView }
    override var emptyView: UIView? { placeholderView }

    init(viewModel: MarketWatchlistViewModel, listViewModel: IMarketListViewModel, headerViewModel: MarketMultiSortHeaderViewModel) {
        self.viewModel = viewModel
        multiSortHeaderView = MarketMultiSortHeaderView(viewModel: headerViewModel, hasTopSeparator: false)

        super.init(listViewModel: listViewModel)

        multiSortHeaderView.viewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        placeholderView.image = UIImage(named: "rate_48")
        placeholderView.text = "market_watchlist.empty.caption".localized

        viewModel.onLoad()
    }

    override func showAddedToWatchlist() {
    }

    override func showRemovedFromWatchlist() {
    }

}
