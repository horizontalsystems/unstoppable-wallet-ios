import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class MarketAdvancedSearchResultViewController: MarketListViewController {
    private let multiSortHeaderView: MarketMultiSortHeaderView

    override var viewController: UIViewController? { self }
    override var headerView: UITableViewHeaderFooterView? { multiSortHeaderView }
    override var refreshEnabled: Bool { false }

    init(listViewModel: IMarketListViewModel, headerViewModel: MarketMultiSortHeaderViewModel) {
        multiSortHeaderView = MarketMultiSortHeaderView(viewModel: headerViewModel)

        super.init(listViewModel: listViewModel, statPage: .advancedSearchResults)

        multiSortHeaderView.viewController = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "market.advanced_search_results.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }
}
