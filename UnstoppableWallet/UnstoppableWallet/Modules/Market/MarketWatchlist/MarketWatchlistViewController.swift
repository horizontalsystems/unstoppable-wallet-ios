import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class MarketWatchlistViewController: MarketListViewController {
    weak var parentNavigationController: UINavigationController?

    private let viewModel: MarketWatchlistViewModel

    private let multiSortHeaderView: MarketMultiSortHeaderView
    private let cautionView = CautionView()

    override var viewController: UIViewController? { parentNavigationController }
    override var headerView: UITableViewHeaderFooterView? { multiSortHeaderView }
    override var emptyView: UIView? { cautionView }

    init(viewModel: MarketWatchlistViewModel, listViewModel: MarketListViewModel, headerViewModel: MarketMultiSortHeaderViewModel) {
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

        cautionView.image = UIImage(named: "rate_48")
        cautionView.text = "market_watchlist.empty.caption".localized
    }

    override func rowActions(index: Int) -> [RowAction] {
        let type = RowActionType.destructive

        return [
            RowAction(
                    pattern: .icon(image: UIImage(named: "star_24")?.withTintColor(type.iconColor), background: type.backgroundColor),
                    action: { [weak self] _ in
                        self?.viewModel.onUnwatch(index: index)
                    }
            )
        ]
    }

}
