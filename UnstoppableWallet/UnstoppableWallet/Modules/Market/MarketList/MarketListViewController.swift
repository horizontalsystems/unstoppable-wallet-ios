import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit

class MarketListViewController: ThemeViewController {
    let listViewModel: MarketListViewModel
    private let disposeBag = DisposeBag()

    let tableView = SectionsTableView(style: .plain)
    private let headerView = MarketListHeaderView()
    private let refreshControl = UIRefreshControl()

    weak var parentNavigationController: UINavigationController?

    private var state: MarketListViewModel.State = .loading

    init(listViewModel: MarketListViewModel) {
        self.listViewModel = listViewModel

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl.tintColor = .themeLeah
        refreshControl.alpha = 0.6
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: G14Cell.self)
        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: ErrorCell.self)

        tableView.sectionDataSource = self

        headerView.setSortingField(image: UIImage(named: "arrow_small_down_20"))
        headerView.set(marketFields: listViewModel.allMarketFields)
        headerView.onTapSortField = { [weak self] in
            self?.onTapSortingField()
        }
        headerView.onSelect = { [weak self] field in
            self?.listViewModel.set(marketField: field)
        }

        subscribe(disposeBag, listViewModel.stateDriver) { [weak self] state in
            self?.state = state
            self?.tableView.reload()
        }
        subscribe(disposeBag, listViewModel.sortingFieldTitleDriver) { [weak self] title in
            self?.headerView.setSortingField(title: title)
        }
        subscribe(disposeBag, listViewModel.marketFieldDriver) { [weak self] marketField in
            self?.headerView.setMarket(field: marketField)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
    }

    @objc func onRefresh() {
        listViewModel.refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func onTapSortingField() {
        let alertController = AlertRouter.module(
                title: "market.sort_by".localized,
                viewItems: listViewModel.sortingFieldViewItems.map { viewItem in
                    AlertViewItem(
                            text: viewItem.title,
                            selected: viewItem.selected
                    )
                }
        ) { [weak self] index in
            self?.listViewModel.setSortingField(at: index)
        }

        present(alertController, animated: true)
    }

    private func row(viewItem: MarketModule.ViewItem, isLast: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: viewItem.coinType.id,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                    MarketModule.bind(cell: cell, viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                })
    }

    private func onSelect(viewItem: MarketModule.ViewItem) {
        let viewController = CoinPageModule.viewController(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: viewItem.coinType))
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    var topSections: [SectionProtocol] {
        []
    }

    var emptyCell: UITableViewCell? {
        nil
    }

    var headerAlwaysVisible: Bool {
        true
    }

}

extension MarketListViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let rows: [RowProtocol]
        var headerVisible = headerAlwaysVisible

        switch state {
        case .loading:
            rows = [
                Row<SpinnerCell>(
                        id: "spinner",
                        dynamicHeight: { [weak self] _ in
                            max(0, (self?.tableView.height ?? 0) - MarketListHeaderView.height)
                        }
                )
            ]

        case .loaded(let viewItems):
            if viewItems.isEmpty {
                if let cell = emptyCell {
                    rows = [
                        StaticRow(
                                cell: cell,
                                id: "caution",
                                dynamicHeight: { [weak self] _ in
                                    max(0, (self?.tableView.height ?? 0) - MarketListHeaderView.height)
                                }
                        )
                    ]
                } else {
                    rows = []
                }
            } else {
                headerVisible = true
                rows = viewItems.enumerated().map { row(viewItem: $1, isLast: $0 == viewItems.count - 1) }
            }

        case .error(let errorDescription):
            rows = [
                Row<ErrorCell>(
                        id: "error",
                        dynamicHeight: { [weak self] _ in
                            max(0, (self?.tableView.height ?? 0) - MarketListHeaderView.height)
                        },
                        bind: { cell, _ in
                            cell.errorText = errorDescription
                        }
                )
            ]
        }

        let headerState: ViewState<MarketListHeaderView> = headerVisible ? .static(view: headerView, height: MarketListHeaderView.height) : .margin(height: 0)

        return topSections + [
            Section(
                    id: "tokens",
                    headerState: headerState,
                    rows: rows
            )
        ]
    }

}
