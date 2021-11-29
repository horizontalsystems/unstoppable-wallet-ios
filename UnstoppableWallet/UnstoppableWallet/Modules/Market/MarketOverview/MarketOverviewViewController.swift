import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD
import Chart

class MarketOverviewViewController: ThemeViewController {
    private let viewModel: MarketOverviewViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = MarketListErrorView()
    private let refreshControl = UIRefreshControl()

    private let marketMetricsCell = MarketOverviewMetricsCell(chartConfiguration: ChartConfiguration.smallChart)

    weak var parentNavigationController: UINavigationController? {
        didSet {
            marketMetricsCell.viewController = parentNavigationController
        }
    }

    private var topViewItems: [MarketOverviewViewModel.TopViewItem]?

    init(viewModel: MarketOverviewViewModel) {
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

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: MarketOverviewHeaderCell.self)
        tableView.registerCell(forClass: G14Cell.self)
        tableView.registerCell(forClass: B1Cell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.onTapRetry = { [weak self] in self?.refresh() }

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] error in
            if let error = error {
                self?.errorView.text = error
                self?.errorView.isHidden = false
            } else {
                self?.errorView.isHidden = true
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
    }

    private func refresh() {
        viewModel.refresh()
    }

    @objc func onRefresh() {
        refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func sync(viewItem: MarketOverviewViewModel.ViewItem?) {
        topViewItems = viewItem?.topViewItems

        if let globalMarketViewItem = viewItem?.globalMarketViewItem {
            marketMetricsCell.set(viewItem: globalMarketViewItem)
        }

        if viewItem != nil {
            tableView.bounces = true
        } else {
            tableView.bounces = false
        }

        tableView.reload()
    }

    private func onSelect(listViewItem: MarketModule.ListViewItem) {
        guard let uid = listViewItem.uid, let module = CoinPageModule.viewController(coinUid: uid) else {
            return
        }

        parentNavigationController?.present(module, animated: true)
    }

    private func didTapSeeAll(listType: MarketOverviewService.ListType) {
        let module = MarketTopModule.viewController(
                marketTop: viewModel.marketTop(listType: listType),
                sortingField: listType.sortingField,
                marketField: listType.marketField
        )
        parentNavigationController?.present(module, animated: true)
    }

}

extension MarketOverviewViewController: SectionsDataSource {

    private func row(listViewItem: MarketModule.ListViewItem, isFirst: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: "\(listViewItem.uid ?? "")-\(listViewItem.name)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst)
                    MarketModule.bind(cell: cell, viewItem: listViewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(listViewItem: listViewItem)
                })
    }

    private func rows(listViewItems: [MarketModule.ListViewItem]) -> [RowProtocol] {
        listViewItems.enumerated().map { index, listViewItem in
            row(listViewItem: listViewItem, isFirst: index == 0)
        }
    }

    private func seeAllRow(id: String, action: @escaping () -> ()) -> RowProtocol {
        Row<B1Cell>(
                id: id,
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isLast: true)
                    cell.title = "market.top.section.header.see_all".localized
                },
                action: { _ in
                    action()
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItems = topViewItems {
            let metricsSection = Section(
                    id: "market_metrics",
                    rows: [
                        StaticRow(
                                cell: marketMetricsCell,
                                id: "metrics",
                                height: MarketOverviewMetricsCell.cellHeight
                        )
                    ]
            )

            sections.append(metricsSection)

            let marketTops = viewModel.marketTops

            for viewItem in viewItems {
                let listType = viewItem.listType
                let currentMarketTopIndex = viewModel.marketTopIndex(listType: listType)

                let headerSection = Section(
                        id: "header_\(listType.rawValue)",
                        footerState: .margin(height: .margin12),
                        rows: [
                            Row<MarketOverviewHeaderCell>(
                                    id: "header_\(listType.rawValue)",
                                    height: .heightCell48,
                                    bind: { [weak self] cell, _ in
                                        cell.set(backgroundStyle: .transparent)

                                        cell.set(values: marketTops)
                                        cell.setSelected(index: currentMarketTopIndex)
                                        cell.onSelect = { index in
                                            self?.viewModel.onSelect(marketTopIndex: index, listType: listType)
                                        }

                                        cell.titleImage = UIImage(named: viewItem.imageName)
                                        cell.title = viewItem.title
                                    }
                            )
                        ]
                )

                let listSection = Section(
                        id: viewItem.listType.rawValue,
                        footerState: .margin(height: .margin24),
                        rows: rows(listViewItems: viewItem.listViewItems) + [
                            seeAllRow(
                                    id: "\(viewItem.listType.rawValue)-see-all",
                                    action: { [weak self] in
                                        self?.didTapSeeAll(listType: viewItem.listType)
                                    }
                            )
                        ]
                )

                sections.append(headerSection)
                sections.append(listSection)
            }
        }

        return sections
    }

}
