import UIKit
import SnapKit
import SectionsTableView
import ThemeKit

class RateListViewController: ThemeViewController {
    private let delegate: IRateListViewDelegate

    private let tableView = SectionsTableView(style: .plain)

    private var viewItems = [RateListModule.CoinViewItem]()
    private var lastUpdated: Date?

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
        tableView.registerHeaderFooter(forClass: RateListHeaderFooterView.self)

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

    private func coinRow(index: Int, viewItem: RateListModule.CoinViewItem) -> RowProtocol {
        let last = index == viewItems.count - 1

        return Row<RateListCell>(
                id: "coin_rate_\(index)",
                hash: viewItem.rate?.hash,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.bind(viewItem: viewItem, last: last)
                },
                action: { [weak self] _ in
                    self?.delegate.onSelectCoin(index: index)
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
                rows: viewItems.enumerated().map { index, viewItem in
                    coinRow(index: index, viewItem: viewItem)
                }
            ),
        ]
    }

}

extension RateListViewController: IRateListView {

    func set(viewItems: [RateListModule.CoinViewItem]) {
        self.viewItems = viewItems
    }

    func set(lastUpdated: Date) {
        self.lastUpdated = lastUpdated
    }

    func refresh() {
        tableView.reload()
    }

}
