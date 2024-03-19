import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class MarketWatchlistViewController: MarketListViewController {
    weak var parentNavigationController: UINavigationController?

    private let viewModel: MarketWatchlistViewModel

    private let singleSortHeaderView: MarketSingleSortHeaderView
    private let placeholderView = PlaceholderView()

    override var viewController: UIViewController? { parentNavigationController }
    override var headerView: UITableViewHeaderFooterView? { singleSortHeaderView }
    override var emptyView: UIView? { placeholderView }

    init(viewModel: MarketWatchlistViewModel, listViewModel: IMarketListViewModel, headerViewModel: MarketSingleSortHeaderViewModel) {
        self.viewModel = viewModel
        singleSortHeaderView = MarketSingleSortHeaderView(viewModel: headerViewModel, hasTopSeparator: false)

        super.init(listViewModel: listViewModel, statPage: .watchlist)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        placeholderView.image = UIImage(named: "rate_48")
        placeholderView.text = "market_watchlist.empty.caption".localized

        viewModel.onLoad()
    }

    override func showAddedToWatchlist() {}

    override func showRemovedFromWatchlist() {}
}
