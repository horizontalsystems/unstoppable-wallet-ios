import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class MarketTopPairsViewController: MarketListViewController {
    private let viewModel: MarketTopPairsViewModel

    override var viewController: UIViewController? { self }
    override var refreshEnabled: Bool { false }

    init(viewModel: MarketTopPairsViewModel, listViewModel: IMarketListViewModel) {
        self.viewModel = viewModel

        super.init(listViewModel: listViewModel, statPage: .topMarketPairs)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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

    override func topSections(loaded _: Bool) -> [SectionProtocol] {
        [
            Section(
                id: "header",
                rows: [
                    Row<MarketHeaderCell>(
                        id: "header",
                        height: MarketHeaderCell.height,
                        bind: { cell, _ in
                            cell.set(
                                title: "top_pairs.title".localized,
                                description: "top_pairs.description".localized,
                                imageMode: .remote(imageUrl: "token_pairs".headerImageUrl)
                            )
                        }
                    ),
                ]
            ),
        ]
    }

    override func onSelect(viewItem: MarketModule.ListViewItem) {
        guard let uid = viewItem.uid, let marketPair = viewModel.marketPair(uid: uid), let tradeUrl = marketPair.tradeUrl else {
            return
        }

        UrlManager.open(url: tradeUrl)
    }
}
