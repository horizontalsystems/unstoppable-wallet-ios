import UIKit
import SnapKit
import ThemeKit

class MarketWatchlistViewController: MarketListViewController {
    weak var parentNavigationController: UINavigationController?

    private let multiSortHeaderView: MarketMultiSortHeaderView
    private let cautionView = CautionView()

    override var viewController: UIViewController? { parentNavigationController }
    override var headerView: UITableViewHeaderFooterView? { multiSortHeaderView }
    override var emptyView: UIView? { cautionView }

    init(listViewModel: MarketListViewModel, headerViewModel: MarketMultiSortHeaderViewModel) {
        multiSortHeaderView = MarketMultiSortHeaderView(viewModel: headerViewModel, hasTopSeparator: false)

        super.init(listViewModel: listViewModel)

        multiSortHeaderView.viewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        cautionView.image = UIImage(named: "rate_48")
        cautionView.text = "market_watchlist.empty.caption".localized
    }

}
