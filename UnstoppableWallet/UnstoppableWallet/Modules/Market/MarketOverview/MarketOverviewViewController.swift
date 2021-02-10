import UIKit
import RxSwift
import ThemeKit
import SectionsTableView

class MarketOverviewViewController: ThemeViewController {
    private let marketViewModel: MarketViewModel
    private let viewModel: MarketOverviewViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let refreshControl = UIRefreshControl()

    private let marketMetricsCell: MarketMetricsCell

    weak var parentNavigationController: UINavigationController?

    private var state: MarketOverviewViewModel.State = .loading

    init(marketViewModel: MarketViewModel, viewModel: MarketOverviewViewModel) {
        self.marketViewModel = marketViewModel
        self.viewModel = viewModel

        marketMetricsCell = MarketMetricsModule.cell()

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

        tableView.registerHeaderFooter(forClass: MarketSectionHeaderView.self)
        tableView.registerCell(forClass: G14Cell.self)
        tableView.registerCell(forClass: A2Cell.self)
        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: ErrorCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)

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

    private func headerRow(listType: MarketModule.ListType) -> RowProtocol {
        Row<A2Cell>(
                id: "section_header_\(listType.rawValue)",
                height: .heightSingleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.value = "market.top.section.header.see_all".localized
                    cell.valueColor = .themeGray

                    switch listType {
                    case .topGainers:
                        cell.titleImage = UIImage(named: "circle_up_20")
                        cell.title = "market.top.section.header.top_gainers".localized
                    case .topLosers:
                        cell.titleImage = UIImage(named: "circle_down_20")
                        cell.title = "market.top.section.header.top_losers".localized
                    case .topVolume:
                        cell.titleImage = UIImage(named: "chart_20")
                        cell.title = "market.top.section.header.top_volume".localized
                    }
                },
                action: { [weak self] _ in
                    self?.didTapSeeAll(listType: listType)
                }
        )
    }

    private func row(viewItem: MarketModule.ViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: viewItem.coinCode,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    MarketModule.bind(cell: cell, viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                }
        )
    }

    private func onSelect(viewItem: MarketModule.ViewItem) {
        let viewController = ChartRouter.module(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: nil))
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func didTapSeeAll(listType: MarketModule.ListType) {
        marketViewModel.handleTapSeeAll(listType: listType)
    }

}

extension MarketOverviewViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "market_metrics",
                    rows: [
                        StaticRow(
                                cell: marketMetricsCell,
                                id: "metrics",
                                height: MarketMetricsCell.cellHeight
                        )
                    ]
            )
        ]

        switch state {
        case .loading:
            let row = Row<SpinnerCell>(
                    id: "spinner",
                    dynamicHeight: { [weak self] _ in
                        max(0, (self?.tableView.height ?? 0) - MarketMetricsCell.cellHeight)
                    }
            )

            sections.append(Section(id: "spinner", rows: [row]))

        case .loaded(let sectionViewItems):
            sectionViewItems.enumerated().forEach { index, sectionViewItem in
                sections.append(
                        Section(id: "header_\(sectionViewItem.listType.rawValue)",
                                footerState: .margin(height: .margin12),
                                rows: [
                                    headerRow(listType: sectionViewItem.listType)
                                ])
                )

                sections.append(
                        Section(
                                id: sectionViewItem.listType.rawValue,
                                footerState: .margin(height: .margin12),
                                rows: sectionViewItem.viewItems.enumerated().map { (index, item) in
                                    row(viewItem: item, isFirst: index == 0, isLast: index == sectionViewItem.viewItems.count - 1)
                                })
                )
            }

            let brandText = "Powered by CoinGecko API"

            sections.append(
                    Section(
                            id: "brand",
                            headerState: .margin(height: .margin24),
                            rows: [
                                Row<BrandFooterCell>(
                                        id: "brand",
                                        dynamicHeight: { containerWidth in
                                            BrandFooterCell.height(containerWidth: containerWidth, title: brandText)
                                        },
                                        bind: { cell, _ in
                                            cell.title = brandText
                                        }
                                )
                            ]
                    )
            )

        case .error(let errorDescription):
            let row = Row<ErrorCell>(
                    id: "error",
                    dynamicHeight: { [weak self] _ in
                        max(0, (self?.tableView.height ?? 0) - MarketMetricsCell.cellHeight)
                    },
                    bind: { cell, _ in
                        cell.errorText = errorDescription
                    }
            )

            sections.append(Section(id: "error", rows: [row]))
        }

        return sections
    }

    public func refresh() {
        marketMetricsCell.refresh()
        viewModel.refresh()
    }

}
