import UIKit
import RxSwift
import ThemeKit
import SectionsTableView

class MarketWatchlistViewController: ThemeViewController {
    private let viewModel: MarketWatchlistViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let headerView = MarketListHeaderView()
    private let refreshControl = UIRefreshControl()

    private let cautionCell = CautionCell()

    weak var parentNavigationController: UINavigationController?

    private var state: MarketWatchlistViewModel.State = .loading

    init(viewModel: MarketWatchlistViewModel) {
        self.viewModel = viewModel

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

        tableView.registerHeaderFooter(forClass: MarketListHeaderView.self)
        tableView.registerCell(forClass: G14Cell.self)

        tableView.sectionDataSource = self

        cautionCell.cautionImage = UIImage(named: "rate_48")
        cautionCell.cautionText = "market_watchlist.empty.caption".localized

        headerView.onTapSortField = { [weak self] in
            self?.onTapSortingField()
        }
        headerView.onSelect = { [weak self] field in
            self?.viewModel.set(marketField: field)
        }

        subscribe(disposeBag, viewModel.stateDriver) { [weak self] state in
            self?.state = state
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.sortingFieldTitleDriver) { [weak self] title in
            self?.headerView.setSortingField(title: title)
        }
        subscribe(disposeBag, viewModel.marketFieldDriver) { [weak self] marketField in
            self?.headerView.setMarketField(field: marketField)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
    }

    @objc func onRefresh() {
        viewModel.refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func onTapSortingField() {
        let alertController = AlertRouter.module(
                title: "market.sort_by".localized,
                viewItems: viewModel.sortingFieldViewItems.map { viewItem in
                    AlertViewItem(
                            text: viewItem.title,
                            selected: viewItem.selected
                    )
                }
        ) { [weak self] index in
            self?.viewModel.setSortingField(at: index)
        }

        present(alertController, animated: true)
    }

    private func row(viewItem: MarketModule.ViewItem, isLast: Bool) -> RowProtocol {
        Row<G14Cell>(
            id: viewItem.coinCode,
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
        let viewController = ChartRouter.module(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: nil))
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

}

extension MarketWatchlistViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let rows: [RowProtocol]
        var headerState: ViewState<MarketListHeaderView> = .margin(height: 0)

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
                rows = [
                    StaticRow(
                            cell: cautionCell,
                            id: "caution",
                            dynamicHeight: { [weak self] _ in
                                max(0, (self?.tableView.height ?? 0) - MarketListHeaderView.height)
                            }
                    )
                ]
            } else {
                headerState = .static(view: headerView, height: MarketListHeaderView.height)
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

        return [
            Section(id: "tokens", headerState: headerState, rows: rows)
        ]
    }

}
