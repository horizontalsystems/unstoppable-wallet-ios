import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class MarketTopViewController: MarketListViewController {
    private let multiSortHeaderView: MarketMultiSortHeaderView

    override var viewController: UIViewController? { self }
    override var headerView: UITableViewHeaderFooterView? { multiSortHeaderView }
    override var refreshEnabled: Bool { false }

    init(listViewModel: IMarketListViewModel, headerViewModel: MarketMultiSortHeaderViewModel) {
        multiSortHeaderView = MarketMultiSortHeaderView(viewModel: headerViewModel, hasLeftSelector: true)

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

        tableView.registerCell(forClass: MarketHeaderCell.self)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    override func topSections(loaded: Bool) -> [SectionProtocol] {
        [
            Section(
                    id: "header",
                    rows: [
                        Row<MarketHeaderCell>(
                                id: "header",
                                height: MarketHeaderCell.height,
                                bind: { cell, _ in
                                    cell.set(
                                            title: "market.top.title".localized,
                                            description: "market.top.description".localized,
                                            imageMode: .remote(imageUrl: "top_coins".headerImageUrl)
                                    )
                                }
                        )
                    ]
            )
        ]
    }

}
