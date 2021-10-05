import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit

class MarketWatchlistViewController: ThemeViewController {
    private let viewModel: MarketWatchlistViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let headerView: MarketMultiSortHeaderView
    private let cautionCell = CautionCell()
    private let refreshControl = UIRefreshControl()

    weak var parentNavigationController: UINavigationController?

    private var state: MarketWatchlistViewModel.State = .loading

    init(viewModel: MarketWatchlistViewModel) {
        self.viewModel = viewModel
        headerView = MarketMultiSortHeaderView(viewModel: viewModel)

        super.init()

        headerView.viewController = self
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

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: G14Cell.self)
        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: ErrorCell.self)

        cautionCell.cautionImage = UIImage(named: "rate_48")
        cautionCell.cautionText = "market_watchlist.empty.caption".localized

        subscribe(disposeBag, viewModel.stateDriver) { [weak self] state in
            self?.state = state
            self?.tableView.reload()
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

    private func onSelect(viewItem: MarketModule.ViewItemNew) {
        guard let viewController = CoinPageModule.viewController(coinUid: viewItem.uid) else {
            return
        }

        parentNavigationController?.present(viewController, animated: true)
    }

}

extension MarketWatchlistViewController: SectionsDataSource {

    private func row(viewItem: MarketModule.ViewItemNew, isLast: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: viewItem.uid,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                    MarketModule.bindNew(cell: cell, viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                })
    }

    func buildSections() -> [SectionProtocol] {
        let rows: [RowProtocol]
        var headerVisible = false

        switch state {
        case .loading:
            rows = [
                Row<SpinnerCell>(
                        id: "spinner",
                        dynamicHeight: { [weak self] _ in
                            max(0, (self?.tableView.height ?? 0) - MarketMultiSortHeaderView.height)
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
                                max(0, (self?.tableView.height ?? 0) - MarketMultiSortHeaderView.height)
                            }
                    )
                ]
            } else {
                headerVisible = true
                rows = viewItems.enumerated().map { row(viewItem: $1, isLast: $0 == viewItems.count - 1) }
            }

        case .failed(let errorDescription):
            rows = [
                Row<ErrorCell>(
                        id: "error",
                        dynamicHeight: { [weak self] _ in
                            max(0, (self?.tableView.height ?? 0) - MarketMultiSortHeaderView.height)
                        },
                        bind: { cell, _ in
                            cell.errorText = errorDescription
                        }
                )
            ]
        }

        let headerState: ViewState<MarketMultiSortHeaderView> = headerVisible ? .static(view: headerView, height: MarketMultiSortHeaderView.height) : .margin(height: 0)

        return [
            Section(
                    id: "tokens",
                    headerState: headerState,
                    rows: rows
            )
        ]
    }

}
