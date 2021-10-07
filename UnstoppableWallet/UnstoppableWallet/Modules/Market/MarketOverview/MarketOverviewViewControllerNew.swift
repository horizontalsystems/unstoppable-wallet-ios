import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit

class MarketOverviewViewControllerNew: ThemeViewController {
    private let topMarketLimits = [250, 500, 1000]

    private let marketViewModel: MarketViewModel
    private let topGainersViewModel: MarketOverviewViewModelNew
    private let topLosersViewModel: MarketOverviewViewModelNew
    private let urlManager: IUrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let refreshControl = UIRefreshControl()

    private let marketMetricsCell: MarketMetricsCellNew

    weak var parentNavigationController: UINavigationController?

    private var topGainersState: MarketOverviewViewModelNew.State = .loading
    private var topLosersState: MarketOverviewViewModelNew.State = .loading

    init(marketViewModel: MarketViewModel, topGainersViewModel: MarketOverviewViewModelNew, topLosersViewModel: MarketOverviewViewModelNew, urlManager: IUrlManager) {
        self.marketViewModel = marketViewModel
        self.topGainersViewModel = topGainersViewModel
        self.topLosersViewModel = topLosersViewModel
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
        tableView.registerCell(forClass: MarketOverviewHeaderCell.self)
        tableView.registerCell(forClass: G14Cell.self)
        tableView.registerCell(forClass: ACell.self)
        tableView.registerCell(forClass: A2Cell.self)
        tableView.registerCell(forClass: B1Cell.self)
        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: ErrorCell.self)
        tableView.registerCell(forClass: MarketPostCell.self)

        subscribe(disposeBag, topGainersViewModel.stateDriver) { [weak self] state in
            self?.topGainersState = state
            self?.tableView.reload()
        }

        subscribe(disposeBag, topLosersViewModel.stateDriver) { [weak self] state in
            self?.topLosersState = state
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

    private func headerRow(listType: MarketModule.ListType, topMarketLimit: Int) -> RowProtocol {
        let filters = topMarketLimits.map { $0.description }
        let currentFilterIndex = topMarketLimits.firstIndex(of: topMarketLimit) ?? 0

        return Row<MarketOverviewHeaderCell>(
                id: "section_header_\(listType.rawValue)",
                height: .heightSingleLineCell,
                autoDeselect: true,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.set(values: filters)
                    cell.setSelected(index: currentFilterIndex)
                    cell.onSelect = { index in
                        self?.onSelect(listType: listType, index: index)
                    }
                    switch listType {
                    case .topGainers:
                        cell.titleImage = UIImage(named: "circle_up_20")
                        cell.title = "market.top.section.header.top_gainers".localized
                    case .topLosers:
                        cell.titleImage = UIImage(named: "circle_down_20")
                        cell.title = "market.top.section.header.top_losers".localized
                    }
                },
                action: { [weak self] _ in
                    self?.didTapSeeAll(listType: listType)
                }
        )
    }

    private func headerSection(listType: MarketModule.ListType) -> SectionProtocol {
        var limit = 0
        switch listType {
        case .topGainers:
            limit = topGainersViewModel.topMarketLimit
        case .topLosers:
            limit = topLosersViewModel.topMarketLimit
        default: ()
        }

        return Section(id: "header_\(listType.rawValue)",
                footerState: .margin(height: .margin12),
                rows: [
                    headerRow(listType: listType, topMarketLimit: limit)
                ])
    }

    private func row(viewItem: MarketModule.ViewItem, isFirst: Bool, action: ((G14Cell) -> ())? = nil) -> RowProtocol {
        Row<G14Cell>(
                id: viewItem.coinCode,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst)
                    MarketModule.bind(cell: cell, viewItem: viewItem)
                },
                action: action
        )
    }

    private func emptyRow(isFirst: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: "loading_cell",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst)
                    MarketModule.bindEmpty(cell: cell)
                }
        )
    }

    private func seeAllRow(id: String, action: (() -> ())?) -> RowProtocol {
        Row<B1Cell>(
                id: id,
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isLast: true)
                    cell.title = "market.top.section.header.see_all".localized
                },
                action: { _ in
                    action?()
                }
        )
    }

    private func rows(listType: MarketModule.ListType, viewItems: [MarketModule.ViewItem]?) -> [RowProtocol] {
        var rows = [RowProtocol]()
        if let viewItems = viewItems {
            rows = viewItems.enumerated().map { (index, item) in
                row(viewItem: item, isFirst: index == 0, action: { [weak self] _ in
                    self?.onSelect(viewItem: item)
                })
            }
        } else {
            rows = Array(0...(MarketOverviewModule.overviewSectionItemCount - 1)).map { index in
                emptyRow(isFirst: index == 0)
            }
        }

        rows.append(seeAllRow(id: "\(MarketModule.ListType.topGainers.rawValue)_seeAll", action: {[weak self] in self?.didTapSeeAll(listType: listType)}))

        return rows
    }

    private func onSelect(listType: MarketModule.ListType, index: Int) {
        switch listType {
        case .topGainers:
            topGainersViewModel.set(topMarketLimit: topMarketLimits[index])
        case .topLosers:
            topLosersViewModel.set(topMarketLimit: topMarketLimits[index])
        default: ()
        }
    }

    private func onSelect(viewItem: MarketModule.ViewItem) {
//        let viewController = CoinPageModule.viewController(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: viewItem.coinType.coinType))
//        parentNavigationController?.present(viewController, animated: true)
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

    private func topSection(listType: MarketModule.ListType, state: MarketOverviewViewModelNew.State, isLast: Bool) -> (success: Bool, sections: [SectionProtocol]) {
        var sections = [SectionProtocol]()
        var success = true

        let footerHeight: CGFloat = isLast ? CGFloat.margin32 : CGFloat.margin24

        switch state {
        case .loading:
            sections.append(headerSection(listType: listType))

            sections.append(
                    Section(
                            id: listType.rawValue,
                            footerState: .margin(height: footerHeight),
                            rows: rows(listType: listType, viewItems: nil))
            )

        case .loaded(let sectionViewItems):
            sections.append(headerSection(listType: listType))

            sections.append(
                    Section(
                            id: listType.rawValue,
                            footerState: .margin(height: footerHeight),
                            rows: rows(listType: listType, viewItems: sectionViewItems))
            )

        case .error(let errorDescription):
            success = false

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

        return (success: success, sections: sections)
    }

}

extension MarketOverviewViewControllerNew: SectionsDataSource {

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

        let (success, gainerSections) = topSection(listType: .topGainers, state: topGainersState, isLast: false)
        sections.append(contentsOf: gainerSections)

        if success {
            let (_ , loserSections) = topSection(listType: .topLosers, state: topLosersState, isLast: true)
            sections.append(contentsOf: loserSections)
        }

        return sections
    }

    public func refresh() {
        marketMetricsCell.refresh()
        topGainersViewModel.refresh()
        topLosersViewModel.refresh()
    }

}
