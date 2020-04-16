import UIKit
import SnapKit
import SectionsTableView
import ThemeKit

class RateListViewController: ThemeViewController {
    private let delegate: IRateListViewDelegate
    private let topMargin: CGFloat

    private let tableView = SectionsTableView(style: .grouped)

    private var item: RateListViewItem?

    init(delegate: IRateListViewDelegate, topMargin: CGFloat) {
        self.delegate = delegate
        self.topMargin = topMargin

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

        tableView.tableFooterView = PostFooterView()
        tableView.tableFooterView?.frame =  CGRect(x: 0, y: 0, width: view.width, height: PostFooterView.height)

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        tableView.registerCell(forClass: RateListCell.self)
        tableView.registerCell(forClass: RateListHeaderCell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)

        delegate.viewDidLoad()

        tableView.buildSections()
    }

    private func lastUpdateText(item: RateListViewItem?) -> String? {
        guard let lastTimestamp = item?.lastUpdateTimestamp else {
            return nil
        }

        return DateHelper.instance.formatRateListTitle(from: Date(timeIntervalSince1970: lastTimestamp))
    }

    private func sectionHeader(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

}

extension RateListViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        guard let item = item else {
            return []
        }

        let count = item.rateViewItems.count

        return [
            Section(
                    id: "header",
                    headerState: .margin(height: topMargin),
                    rows: [
                        Row<RateListHeaderCell>(
                                id: "header_cell",
                                hash: "\(item.lastUpdateTimestamp ?? 0)",
                                height: RateListHeaderCell.height,
                                bind: { [weak self] cell, _ in
                                    cell.bind(title: "rate_list.title".localized, lastUpdated: self?.lastUpdateText(item: item))
                                }
                        )
                    ]
            ),
            Section(
                    id: "rate_list_section",
                    headerState: sectionHeader(text: "rate_list.portfolio".localized),
                    rows: item.rateViewItems.enumerated().map { index, viewItem in
                        Row<RateListCell>(
                                id: "rate_\(index)",
                                hash: viewItem.hash,
                                height: .heightDoubleLineCell,
                                autoDeselect: true,
                                bind: { cell, _ in
                                    cell.selectionStyle = viewItem.diff == nil ? .none : .default
                                    cell.bind(viewItem: viewItem, last: index == count - 1)
                                },
                                action: { [weak self] _ in
                                    self?.delegate.onSelect(viewItem: viewItem)
                                }
                        )
                    }
            )
        ]
    }

}

extension RateListViewController: IRateListView {

    func show(item: RateListViewItem) {
        self.item = item

        tableView.reload()
    }

}
