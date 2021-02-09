import UIKit
import SnapKit
import SectionsTableView
import ThemeKit

class RateListViewController: ThemeViewController {
    private let delegate: IRateListViewDelegate

    private let tableView = SectionsTableView(style: .plain)

    private var coinViewItems = [RateListModule.CoinViewItem]()
    private var postViewItems = [RateListModule.PostViewItem]()
    private var lastUpdated: Date?
    private var postSpinnerVisible = false

    init(delegate: IRateListViewDelegate) {
        self.delegate = delegate

        super.init(gradient: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        tableView.registerCell(forClass: RateListCell.self)
        tableView.registerCell(forClass: PostCell.self)
        tableView.registerHeaderFooter(forClass: RateListHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: PostsHeaderFooterView.self)

        delegate.onLoad()

        tableView.buildSections()
    }

    private func coinsHeader() -> ViewState<RateListHeaderFooterView> {
        .cellType(
                hash: "coins_header",
                binder: { [weak self] view in
                    view.bind(title: "rate_list.portfolio".localized, lastUpdated: self?.lastUpdated, sortButtonState: .hidden)
                },
                dynamicHeight: { _ in
                    RateListHeaderFooterView.height
                }
        )
    }

    private func postsHeader(spinnerVisible: Bool) -> ViewState<PostsHeaderFooterView> {
        .cellType(
                hash: "posts_header",
                binder: { view in
                    view.bind(spinnerVisible: spinnerVisible)
                },
                dynamicHeight: { _ in
                    .heightCell48
                }
        )
    }

    private func coinRow(index: Int, viewItem: RateListModule.CoinViewItem) -> RowProtocol {
        let isLast = index == coinViewItems.count - 1

        return Row<RateListCell>(
                id: "coin_rate_\(index)",
                hash: viewItem.rate?.hash,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .claude, isLast: isLast)
                    cell.bind(viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.delegate.onSelectCoin(index: index)
                }
        )

    }

    private func postRow(index: Int, viewItem: RateListModule.PostViewItem, isLast: Bool) -> RowProtocol {
        Row<PostCell>(
                id: "post_\(index)",
                autoDeselect: true,
                dynamicHeight: { containerWidth in
                    PostCell.height(containerWidth: containerWidth, viewItem: viewItem)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .claude, isFirst: index == 0, isLast: isLast)
                    cell.bind(viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.delegate.onSelectPost(index: index)
                }
        )

    }

}

extension RateListViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "rate_list_section",
                headerState: coinsHeader(),
                footerState: .marginColor(height: .margin8x, color: .clear),
                rows: coinViewItems.enumerated().map { index, viewItem in
                    coinRow(index: index, viewItem: viewItem)
                }
            ),
            Section(
                id: "posts_section",
                headerState: postsHeader(spinnerVisible: postSpinnerVisible),
                footerState: .marginColor(height: .margin8x, color: .clear),
                rows: postViewItems.enumerated().map { index, viewItem in
                    postRow(index: index, viewItem: viewItem, isLast: index == postViewItems.count - 1)
                }
            ),
        ]
    }

}

extension RateListViewController: IRateListView {

    func set(coinViewItems: [RateListModule.CoinViewItem]) {
        self.coinViewItems = coinViewItems
    }

    func set(postViewItems: [RateListModule.PostViewItem]) {
        self.postViewItems = postViewItems
    }

    func set(lastUpdated: Date) {
        self.lastUpdated = lastUpdated
    }

    func setPostSpinner(visible: Bool) {
        self.postSpinnerVisible = visible
    }

    func refresh() {
        tableView.reload()
    }

}
