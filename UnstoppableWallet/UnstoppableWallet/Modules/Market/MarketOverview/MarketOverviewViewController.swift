import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit

class MarketOverviewViewController: ThemeViewController {
    private let marketViewModel: MarketViewModel
    private let postViewModel: MarketPostViewModel
    private let overviewViewModel: MarketOverviewViewModel
    private let urlManager: IUrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let refreshControl = UIRefreshControl()

    private let marketMetricsCell: MarketMetricsCellNew

    weak var parentNavigationController: UINavigationController?

    private var overviewState: MarketOverviewViewModel.State = .loading
    private var postState: MarketPostViewModel.State = .loading

    init(marketViewModel: MarketViewModel, postViewModel: MarketPostViewModel, overviewViewModel: MarketOverviewViewModel, urlManager: IUrlManager) {
        self.marketViewModel = marketViewModel
        self.postViewModel = postViewModel
        self.overviewViewModel = overviewViewModel
        self.urlManager = urlManager

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
        tableView.registerCell(forClass: ACell.self)
        tableView.registerCell(forClass: A2Cell.self)
        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: ErrorCell.self)
        tableView.registerCell(forClass: MarketPostCell.self)

        subscribe(disposeBag, overviewViewModel.stateDriver) { [weak self] state in
            self?.overviewState = state
            self?.tableView.reload()
        }

        subscribe(disposeBag, postViewModel.stateDriver) { [weak self] state in
            self?.postState = state
            self?.tableView.reload()
        }

        subscribe(disposeBag, marketMetricsCell.onTapMetricsSignal) { [weak self] in self?.onTap(metricType: $0) }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
    }

    @objc func onRefresh() {
        refresh()

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

    private func row(viewItem: MarketPostViewModel.ViewItem) -> RowProtocol {
        Row<MarketPostCell>(
                id: viewItem.title,
                height: MarketPostCell.height,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                    cell.set(source: viewItem.source, title: viewItem.title, description: viewItem.body, date: viewItem.timestamp)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                }
        )
    }

    private func onSelect(viewItem: MarketModule.ViewItem) {
        let viewController = CoinPageModule.viewController(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: viewItem.coinType))
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func onSelect(viewItem: MarketPostViewModel.ViewItem) {
        urlManager.open(url: viewItem.url, from: parentNavigationController)
    }

    private func onTap(metricType: MarketGlobalModule.MetricsType) {
        let viewController = MarketGlobalModule.viewController(type: metricType)
        present(viewController, animated: true)
    }

    private func didTapSeeAll(listType: MarketModule.ListType) {
        marketViewModel.handleTapSeeAll(listType: listType)
    }

    private var postSections: [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(
                Section(id: "header_posts",
                        footerState: .margin(height: .margin12),
                        rows: [
                            Row<ACell>(
                                    id: "posts_header_section",
                                    height: .heightSingleLineCell,
                                    autoDeselect: true,
                                    bind: { cell, _ in
                                        cell.set(backgroundStyle: .transparent)

                                        cell.titleImage = UIImage(named: "message_square_20")
                                        cell.title = "market.top.section.header.news".localized

                                        cell.selectionStyle = .none
                                    }
                            )]
                )
        )

        switch postState {
        case .loading:
            let row = Row<SpinnerCell>(
                    id: "post_spinner",
                    height: .heightCell48
            )

            sections.append(Section(id: "post_spinner", rows: [row]))
        case .error(let errorDescription):
            let row = Row<ErrorCell>(
                    id: "post_error",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.errorText = errorDescription
                    }
            )

            sections.append(Section(id: "post_error", rows: [row]))
        case .loaded(let postViewItems):
            guard !postViewItems.isEmpty else {
                return sections
            }

            sections.append(contentsOf:
                    postViewItems.enumerated().map { (index, item) in Section(
                            id: "post_\(index)",
                            footerState: .margin(height: .margin12),
                            rows: [row(viewItem: item)]
                    )})
        }

        return sections
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
                                height: MarketMetricsCellNew.cellHeight
                        )
                    ]
            )
        ]

        switch overviewState {
        case .loading:
            let row = Row<SpinnerCell>(
                    id: "spinner",
                    dynamicHeight: { [weak self] _ in
                        max(0, (self?.tableView.height ?? 0) - MarketMetricsCellNew.cellHeight)
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

            // posts state showed only when completed coin request
            sections.append(contentsOf: postSections)

        case .error(let errorDescription):
            let row = Row<ErrorCell>(
                    id: "error",
                    dynamicHeight: { [weak self] _ in
                        max(0, (self?.tableView.height ?? 0) - MarketMetricsCellNew.cellHeight)
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
        overviewViewModel.refresh()
        postViewModel.refresh()
    }

}
