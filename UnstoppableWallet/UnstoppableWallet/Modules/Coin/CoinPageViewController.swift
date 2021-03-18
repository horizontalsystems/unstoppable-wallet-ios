import UIKit
import XRatesKit
import RxSwift
import ThemeKit
import SectionsTableView
import SnapKit
import HUD
import Chart

class CoinPageViewController: ThemeViewController {
    private let viewModel: CoinPageViewModel
    private let chartViewModel: CoinChartViewModel
    private var urlManager: IUrlManager
    private let disposeBag = DisposeBag()

    private var viewItem: CoinPageViewModel.ViewItem?

    private let tableView = SectionsTableView(style: .grouped)
    private let subtitleCell = AdditionalDataCell()

    /* Chart section */
    private let currentRateCell: CoinChartRateCell
    private let chartIntervalAndSelectedRateCell = ChartIntervalAndSelectedRateCell()
    private let chartViewCell: ChartViewCell
    private let indicatorSelectorCell = IndicatorSelectorCell()

    init(viewModel: CoinPageViewModel, chartViewModel: CoinChartViewModel, configuration: ChartConfiguration, urlManager: IUrlManager) {
        self.viewModel = viewModel
        self.chartViewModel = chartViewModel
        self.urlManager = urlManager

        currentRateCell = CoinChartRateCell(viewModel: chartViewModel)
        chartViewCell = ChartViewCell(configuration: configuration)

        super.init()

        chartViewCell.delegate = self

        hidesBottomBarWhenPushed = true
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

        title = viewModel.title

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: A1Cell.self)
        tableView.registerCell(forClass: B1Cell.self)
        tableView.registerCell(forClass: B4Cell.self)
        tableView.registerCell(forClass: PriceIndicatorCell.self)
        tableView.registerCell(forClass: ChartMarketPerformanceCell.self)
        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)

        subtitleCell.bind(title: viewModel.subtitle, value: nil)
        subscribeViewModels()
    }

    private func subscribeViewModels() {
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] in self?.sync(loading: $0) }
        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }

        // chart section
        subscribe(disposeBag, chartViewModel.loadingDriver) { [weak self] in self?.syncChart(loading: $0) }
        subscribe(disposeBag, chartViewModel.errorDriver) { [weak self] in self?.syncChart(error: $0) }
        subscribe(disposeBag, chartViewModel.chartInfoDriver) { [weak self] in self?.syncChart(viewItem: $0) }
    }

    private func reloadTable() {
        tableView.buildSections()

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension CoinPageViewController {

    private func sync(loading: Bool) {
//        tableView.reload()
    }

    private func sync(viewItem: CoinPageViewModel.ViewItem?) {
        self.viewItem = viewItem
        tableView.reload()
    }

    // Chart section

    private func deactivateIndicators() {
        ChartIndicatorSet.all.forEach { indicator in
            indicatorSelectorCell.bind(indicator: indicator, selected: false)
        }
    }

    private func syncChart(viewItem: CoinChartViewModel.ViewItem?) {
        guard let viewItem = viewItem else {
            return
        }

        chartViewCell.set(data: viewItem)

//        ChartIndicatorSet.all.forEach { indicator in
//            let show = viewItem.selectedIndicator.contains(indicator)
//
//            chartViewCell.bind(indicator: indicator, hidden: !show)
//
//            indicatorSelectorCell.bind(indicator: indicator, selected: show)
//        }
    }

    private func syncChart(loading: Bool) {
        if loading {
            chartViewCell.showLoading()
            deactivateIndicators()
        } else {
            chartViewCell.hideLoading()
        }
    }

    private func syncChart(error: String?) { //todo: check logic!
        if error != nil {
            deactivateIndicators()
        }
    }

}

extension CoinPageViewController {

    private var subtitleSection: SectionProtocol {
        Section(id: "subtitle",
                rows: [StaticRow(
                        cell: subtitleCell,
                        id: "subtitle",
                        height: AdditionalDataCell.height
                )])
    }

    private var chartSection: SectionProtocol {
        Section(id: "chart",
                footerState: .margin(height: .margin12),
                rows: [
                    StaticRow(
                        cell: currentRateCell,
                        id: "currentRate",
                        height: ChartCurrentRateCell.cellHeight),
                    StaticRow(
                        cell: chartIntervalAndSelectedRateCell,
                        id: "chartIntervalAndSelectedRate",
                        height: .heightSingleLineCell),
                    StaticRow(
                        cell: chartViewCell,
                        id: "chartView",
                        height: ChartViewCell.cellHeight),
                    StaticRow(
                        cell: indicatorSelectorCell,
                        id: "indicatorSelector",
                        height: .heightSingleLineCell),
                ])
    }

    private func linksSection(links: [CoinPageViewModel.Link]) -> SectionProtocol {
        Section(
                id: "links",
                headerState: .margin(height: .margin12),
                rows: links.enumerated().map { index, link in
                    let isFirst = index == 0
                    let isLast = index == links.count - 1

                    return Row<A1Cell>(
                            id: link.type.rawValue,
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                cell.titleImage = link.icon
                                cell.title = link.title
                            },
                            action: { [weak self] _ in
                                self?.open(link: link)
                            }
                    )
                }
        )
    }

    private func open(link: CoinPageViewModel.Link) {
        urlManager.open(url: link.url, from: self)
    }

    private func poweredBySection(text: String) -> SectionProtocol {
        Section(
                id: "powered-by",
                headerState: .margin(height: .margin32),
                rows: [
                    Row<BrandFooterCell>(
                            id: "powered-by",
                            dynamicHeight: { containerWidth in
                                BrandFooterCell.height(containerWidth: containerWidth, title: text)
                            },
                            bind: { cell, _ in
                                cell.title = text
                            }
                    )
                ]
        )
    }

    private func marketsSection() -> SectionProtocol {
        let marketsTitle = "coin_page.markets".localized(viewModel.coinCode)
        let investorsTitle = "coin_page.investors".localized(viewModel.coinCode)

        return Section(
                id: "markets",
                rows: [
                    Row<B1Cell>(
                            id: "markets",
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: true)
                                cell.title = marketsTitle
                            },
                            action: { [weak self] _ in
                            }
                    ),
                    Row<B1Cell>(
                            id: "investors",
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isLast: true)
                                cell.title = investorsTitle
                            },
                            action: { [weak self] _ in
                            }
                    )
                ]
        )
    }

}

extension CoinPageViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(subtitleSection)
        sections.append(chartSection)

        if let viewItem = viewItem {
            sections.append(marketsSection())

            if !viewItem.links.isEmpty {
                sections.append(linksSection(links: viewItem.links))
            }

            sections.append(poweredBySection(text: "Powered by CoinGecko API"))
        }

        return sections
    }

}

extension CoinPageViewController: IChartViewTouchDelegate {

    public func touchDown() {
    }

    public func select(item: ChartItem) {
    }

    public func touchUp() {
    }

}