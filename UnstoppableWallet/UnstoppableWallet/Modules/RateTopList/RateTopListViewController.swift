import UIKit
import SnapKit
import SectionsTableView
import ThemeKit
import HUD

class RateTopListViewController: ThemeViewController {
    private let delegate: IRateTopListViewDelegate

    private let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .large48)

    private var viewItems = [RateTopListModule.ViewItem]()
    private var lastUpdated: Date?
    private var sortButtonEnabled = false

    init(delegate: IRateTopListViewDelegate) {
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

        tableView.registerCell(forClass: RateTopListCell.self)
        tableView.registerHeaderFooter(forClass: RateListHeaderFooterView.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        delegate.onLoad()

        tableView.buildSections()
    }

    private func header() -> ViewState<RateListHeaderFooterView> {
        let sortButtonState: RateListHeaderFooterView.SortButtonState

        if sortButtonEnabled {
            sortButtonState = .enabled { [weak self] in self?.delegate.onTapSort() }
        } else {
            sortButtonState = .disabled
        }

        return .cellType(
                hash: "header",
                binder: { [weak self] view in
                    view.bind(title: "top100_list.portfolio".localized, lastUpdated: self?.lastUpdated, sortButtonState: sortButtonState)
                },
                dynamicHeight: { _ in
                    RateListHeaderFooterView.height
                }
        )
    }

    private func row(index: Int, viewItem: RateTopListModule.ViewItem) -> RowProtocol {
        let isLast = index == viewItems.count - 1

        return Row<RateTopListCell>(
                id: "coin_rate_\(index)",
                hash: viewItem.rate.hash,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .claude, isLast: isLast)
                    cell.bind(viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.delegate.onSelect(index: index)
                }
        )

    }

}

extension RateTopListViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "top_markets",
                    headerState: header(),
                    footerState: .marginColor(height: .margin8x, color: .clear),
                    rows: viewItems.enumerated().map { index, viewItem in
                        row(index: index, viewItem: viewItem)
                    }
            ),
        ]
    }

}

extension RateTopListViewController: IRateTopListView {

    func set(viewItems: [RateTopListModule.ViewItem]) {
        self.viewItems = viewItems
    }

    func set(lastUpdated: Date) {
        self.lastUpdated = lastUpdated
    }

    func refresh() {
        tableView.reload()
    }

    func setSpinner(visible: Bool) {
        if visible {
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            spinner.isHidden = true
            spinner.stopAnimating()
        }
    }

    func setSortButton(enabled: Bool) {
        sortButtonEnabled = enabled
    }

}
