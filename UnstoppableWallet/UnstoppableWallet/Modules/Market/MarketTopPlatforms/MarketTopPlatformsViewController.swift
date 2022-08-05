import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class MarketTopPlatformsViewController: MarketListViewController {
    private let viewModel: MarketTopPlatformsViewModel
    private let multiSortHeaderView: MarketMultiSortHeaderView

    override var viewController: UIViewController? { self }
    override var headerView: UITableViewHeaderFooterView? { multiSortHeaderView }
    override var refreshEnabled: Bool { false }

    init(viewModel: MarketTopPlatformsViewModel, listViewModel: IMarketListViewModel, headerViewModel: TopPlatformsMultiSortHeaderViewModel) {
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

        tableView.registerCell(forClass: MarketTopHeaderCell.self)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    override func topSections(loaded: Bool) -> [SectionProtocol] {
        let viewModel = viewModel
        return [
            Section(
                    id: "header",
                    rows: [
                        Row<MarketTopHeaderCell>(
                                id: "header",
                                height: MarketTopHeaderCell.height,
                                bind: { cell, _ in
                                    cell.set(title: viewModel.title, description: viewModel.description, imageName: viewModel.imageName)
                                }
                        )
                    ]
            )
        ]
    }

    override func onSelect(viewItem: MarketModule.ListViewItem) {
        guard let uid = viewItem.uid, let topPlatform = viewModel.topPlatform(uid: uid) else {
            return
        }

        present(TopPlatformModule.viewController(topPlatform: topPlatform), animated: true)
    }

}
