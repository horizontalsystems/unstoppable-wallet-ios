import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class MarketNftTopCollectionsViewController: MarketListViewController {
    private let viewModel: MarketNftTopCollectionsViewModel
    private let multiSortHeaderView: MarketMultiSortHeaderView

    override var viewController: UIViewController? { self }
    override var headerView: UITableViewHeaderFooterView? { multiSortHeaderView }
    override var refreshEnabled: Bool { false }

    init(viewModel: MarketNftTopCollectionsViewModel, listViewModel: IMarketListViewModel, headerViewModel: NftCollectionsMultiSortHeaderViewModel) {
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
                                            title: "top_nft_collections.title".localized,
                                            description: "top_nft_collections.description".localized,
                                            imageMode: .remote(imageUrl: "nft".headerImageUrl)
                                    )
                                }
                        )
                    ]
            )
        ]
    }

    override func onSelect(viewItem: MarketModule.ListViewItem) {
        guard let uid = viewItem.uid, let topCollection = viewModel.topCollection(uid: uid) else {
            return
        }

        if let module = NftCollectionModule.viewController(blockchainType: topCollection.blockchainType, providerCollectionUid: topCollection.providerUid) {
            present(ThemeNavigationController(rootViewController: module), animated: true)
        }
    }

}
