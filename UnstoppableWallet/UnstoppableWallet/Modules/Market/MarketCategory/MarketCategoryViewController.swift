import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class MarketCategoryViewController: MarketListViewController {
    private let viewModel: MarketCategoryViewModel
    private let multiSortHeaderView: MarketMultiSortHeaderView

    override var viewController: UIViewController? { self }
    override var headerView: UITableViewHeaderFooterView? { multiSortHeaderView }
    override var refreshEnabled: Bool { false }

    init(viewModel: MarketCategoryViewModel, listViewModel: IMarketListViewModel, headerViewModel: MarketMultiSortHeaderViewModel) {
        self.viewModel = viewModel
        multiSortHeaderView = MarketMultiSortHeaderView(viewModel: headerViewModel)

        super.init(listViewModel: listViewModel)

        multiSortHeaderView.viewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        tableView.registerCell(forClass: MarketCategoryHeaderCell.self)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    override func topSections(loaded: Bool) -> [SectionProtocol] {
        [
            Section(
                    id: "header",
                    rows: [
                        Row<MarketCategoryHeaderCell>(
                                id: "header",
                                height: MarketCategoryHeaderCell.height,
                                bind: { [weak self] cell, _ in
                                    self?.bind(cell: cell)
                                }
                        )
                    ]
            )
        ]
    }

    private func bind(cell: MarketCategoryHeaderCell) {
        cell.set(viewItem: viewModel.viewItem)
    }

}
