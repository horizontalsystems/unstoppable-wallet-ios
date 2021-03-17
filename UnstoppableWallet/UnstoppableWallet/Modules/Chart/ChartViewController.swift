import UIKit
import XRatesKit
import ThemeKit
import SectionsTableView
import SnapKit
import HUD
import Chart

extension ChartType {
    var title: String {
        switch self {
        case .today: return "chart.time_duration.today".localized
        case .day: return "chart.time_duration.day".localized
        case .week: return "chart.time_duration.week".localized
        case .week2: return "chart.time_duration.week2".localized
        case .month: return "chart.time_duration.month".localized
        case .month3: return "chart.time_duration.month3".localized
        case .halfYear: return "chart.time_duration.halyear".localized
        case .year: return "chart.time_duration.year".localized
        case .year2: return "chart.time_duration.year2".localized
        }
    }
}

class ChartViewController: ThemeViewController {
    private let delegate: IChartViewDelegate & IChartViewTouchDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private let container = UIView()

    private let currentRateCell = ChartCurrentRateCell()
    private let chartIntervalAndSelectedRateCell = ChartIntervalAndSelectedRateCell()
    private let chartViewCell: ChartViewCell
    private let indicatorSelectorCell = IndicatorSelectorCell()
    private let ratingCell = A2Cell()
    private let marketInfoCell = MarketInfoCell()
    private let openMarketsCell = B1Cell()
    private let descriptionTextCell = ReadMoreTextCell()
    private let returnOfInvestmentsCell = ReturnOfInvestmentsTableViewCell()

    private var favoriteButtonItem: UIBarButtonItem?
    private var alertButtonItem: UIBarButtonItem?

    private var priceIndicatorItems = [PriceIndicatorViewItem]()

    //todo get performance
    let weekPerformance = [
        MultiTextMetricsView.MetricsViewItem(
                value: "USD",
                valueChange: "+56,62%",
                valueChangeColor: .themeRemus
        ),
        MultiTextMetricsView.MetricsViewItem(
                value: "ETH",
                valueChange: "+9,24%",
                valueChangeColor: .themeRemus
        ),
        MultiTextMetricsView.MetricsViewItem(
                value: "BTC",
                valueChange: "-1,03%",
                valueChangeColor: .themeRedD
        )
    ]
    let monthPerformance = [
        MultiTextMetricsView.MetricsViewItem(
                value: "USD",
                valueChange: "+236,62%",
                valueChangeColor: .themeRemus
        ),
        MultiTextMetricsView.MetricsViewItem(
                value: "ETH",
                valueChange: "+112,09%",
                valueChangeColor: .themeRemus
        ),
        MultiTextMetricsView.MetricsViewItem(
                value: "BTC",
                valueChange: "+10,93%",
                valueChangeColor: .themeRedD
        )
    ]
    //todo get note text
    let noteText: String? = "Bitcoin is a cryptocurrency and worldwide payment system. It is the first decentralized digital currency, as the system works without a central bank or single administrator."
    //todo get roi items
    let returnOfInvestmentsViewItems: [[ReturnOfInvestmentsTableViewCell.CellType]] = [
        [
            .title("ROI"),
            .subtitle("USD"),
            .subtitle("BTC"),
            .subtitle("ETH"),
        ],
        [
            .content("1 Week"),
            .value(Decimal(56.62)),
            .value(Decimal(10.93)),
            .value(Decimal(9.24)),
        ],
        [
            .content("1 Month"),
            .value(Decimal(136.62)),
            .value(Decimal(-1.03)),
            .value(Decimal(112.09)),
        ]
    ]

    init(delegate: IChartViewDelegate & IChartViewTouchDelegate, configuration: ChartConfiguration) {
        self.delegate = delegate
        chartViewCell = ChartViewCell(delegate: delegate, configuration: configuration)

        super.init()

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

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: B4Cell.self)
        tableView.registerCell(forClass: PriceIndicatorCell.self)
        tableView.registerCell(forClass: ChartMarketPerformanceCell.self)
        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)

        chartIntervalAndSelectedRateCell.onSelectInterval = { [weak self] index in
            self?.delegate.onSelectType(at: index)
        }
        indicatorSelectorCell.onTapIndicator = { [weak self] indicator in
            self?.delegate.onTap(indicator: indicator)
        }

        ratingCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        ratingCell.title = " "
        ratingCell.value = "chart.rating_details".localized
        ratingCell.valueColor = .themeJacob
        ratingCell.disclosureImageTintColor = .themeJacob

        ratingCell.titleImage = UIImage(named: "rating_a_24")?.tinted(with: .themeJacob)//todo get icon from view model

        priceIndicatorItems = [//todo price indicators
            PriceIndicatorViewItem(low: "$19345", high: "$43310", range: .day, currentPercentage: 0.4),
            PriceIndicatorViewItem(low: "$5000", high: "$50000", range: .year, currentPercentage: 0.78)
        ]

        marketInfoCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        //todo market data
        marketInfoCell.bind(marketCap: "$178.3B", marketCapChange: "+34,56%", volume: "$2.32B", circulation: "18.4B BTC", totalSupply: "21B BTC")

        openMarketsCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        //todo get coin code
        openMarketsCell.title = "chart.market.show_markets".localized("BTC")

        descriptionTextCell.set(backgroundStyle: .transparent, isFirst: true)
        descriptionTextCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }

        //todo get description
        descriptionTextCell.contentText = "Bitcoin is a cryptocurrency and worldwide payment system. It is the first decentralized digital currency, as the system works without a central bank or single administrator. Bitcoin is a cryptocurrency and worldwide payment system. It is the first decentralized digital currency, as the system works without a central bank or single administrator. \nBitcoin is a cryptocurrency and worldwide payment system. It is the first decentralized digital currency, as the system works without a central bank or single administrator. Bitcoin is a cryptocurrency and worldwide payment system. It is the first decentralized digital currency, as the system works without a central bank or single administrator. Cryptocurrencies are powered by a number of technologies, but primarily a blockchain technology. The blockchain technology used in cryptocurrencies like Bitcoin was built around a principle that 'no party can be trusted'. \nThe aim of this guide is to onboard someone with little knowledge about cryptocurrencies to the comfortable level as quickly as possible."

        returnOfInvestmentsCell.set(items: returnOfInvestmentsViewItems)

        tableView.buildSections()

        delegate.onLoad()
    }

    private func updateViews(viewItem: ChartViewItem) {
        currentRateCell.bind(rate: viewItem.currentRate, diff: nil)
        updateAlertBarItem(alertMode: viewItem.priceAlertMode)

        switch viewItem.chartDataStatus {
        case .loading:
            chartViewCell.showLoading()
            deactivateIndicators()
        case .failed:
            deactivateIndicators()
        case .completed(let data):
            chartViewCell.hideLoading()

            currentRateCell.bind(rate: viewItem.currentRate, diff: data.chartDiff)

            chartViewCell.bind(data: data, viewItem: viewItem)

            ChartIndicatorSet.all.forEach { indicator in
                let show = viewItem.selectedIndicator.contains(indicator)

                chartViewCell.bind(indicator: indicator, hidden: !show)

                indicatorSelectorCell.bind(indicator: indicator, selected: show)
            }
        }
    }

    private func deactivateIndicators() {
        ChartIndicatorSet.all.forEach { indicator in
            indicatorSelectorCell.bind(indicator: indicator, selected: false)
        }
    }

    private func updateAlertBarItem(alertMode: ChartPriceAlertMode) {
        switch alertMode {
        case .on:
            let image = UIImage(named: "bell_ring_24")?.tinted(with: .themeJacob)?.withRenderingMode(.alwaysOriginal)
            alertButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(onAlertTap))
        case .off:
            let image = UIImage(named: "bell_24")?.tinted(with: .themeGray)?.withRenderingMode(.alwaysOriginal)
            alertButtonItem = UIBarButtonItem(image: image, style: .done, target: self, action: #selector(onAlertTap))
        case .hidden:
            alertButtonItem = nil
        }

        updateBarButtons()
    }

    private func updateBarButtons() {
        navigationItem.rightBarButtonItems = [favoriteButtonItem, alertButtonItem].compactMap { $0 }
    }

    @objc private func onAlertTap() {
        delegate.onTapAlert()
    }

    @objc private func onFavoriteTap() {
        delegate.onTapFavorite()
    }

    @objc private func onUnfavoriteTap() {
        delegate.onTapUnfavorite()
    }

    private func reloadTable() {
        tableView.buildSections()

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension ChartViewController: IChartView {

    func set(title: String) {
        self.title = title.localized
    }

    func set(favorite: Bool) {
        let selector = favorite ? #selector(onUnfavoriteTap) : #selector(onFavoriteTap)
        let color = favorite ? UIColor.themeJacob : UIColor.themeGray

        let favoriteImage = UIImage(named: "rate_24")?.tinted(with: color)?.withRenderingMode(.alwaysOriginal)
        favoriteButtonItem = UIBarButtonItem(image: favoriteImage, style: .plain, target: self, action: selector)

        updateBarButtons()
    }

    // Interval selecting functions
    func set(types: [String]) {
        chartIntervalAndSelectedRateCell.bind(filters: types.map { .item(title: $0.uppercased()) })
    }

    func setSelectedType(at index: Int?) {
        guard let index = index else {
            return
        }

        chartIntervalAndSelectedRateCell.select(index: index)
    }

    // Chart data functions
    func set(viewItem: ChartViewItem) {
        updateViews(viewItem: viewItem)
    }

    func setSelectedState(hidden: Bool) {
        chartIntervalAndSelectedRateCell.bind(displayMode: hidden ? .interval : .selectedRate)
    }

    func showSelectedPoint(viewItem: SelectedPointViewItem) {
        chartIntervalAndSelectedRateCell.bind(selectedPointViewItem: viewItem)
    }

}

extension ChartViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        643
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        container
    }

}

extension ChartViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        sections.append(contentsOf: [
            Section(id: "chart", footerState: .margin(height: .margin12), rows: [
                StaticRow(
                        cell: currentRateCell,
                        id: "current_rate",
                        height: ChartCurrentRateCell.cellHeight
                ),
                StaticRow(
                        cell: chartIntervalAndSelectedRateCell,
                        id: "select_interval",
                        height: .heightSingleLineCell
                ),
                StaticRow(
                        cell: chartViewCell,
                        id: "chart_view",
                        height: ChartViewCell.cellHeight
                ),
                StaticRow(
                        cell: indicatorSelectorCell,
                        id: "indicator_selector",
                        height: .heightSingleLineCell
                )
            ]),
            Section(id: "return_of_investments_section", footerState: .margin(height: .margin12), rows: [
                StaticRow(
                        cell: returnOfInvestmentsCell,
                        id: "return_of_investments_cell",
                        height: returnOfInvestmentsCell.cellHeight(rowCount: returnOfInvestmentsViewItems.count)
                )
            ]),
            Section(id: "rating", footerState: .margin(height: .margin12), rows: [
                StaticRow(
                        cell: ratingCell,
                        id: "rating",
                        height: .heightSingleLineCell,
                        autoDeselect: true,
                        action: {
                            print("open rating details")
                        }
                ),
            ])
        ])

        if !priceIndicatorItems.isEmpty {
            sections.append(contentsOf: [
                Section(id: "price_header", footerState: .margin(height: .margin12), rows: [headerRow(title: "price".localized)]),
                Section(id: "price_indicators", footerState: .margin(height: .margin12), rows: priceIndicatorRows())
            ])
        }

        var aboutSectionRows: [RowProtocol] = [
            StaticRow(
                    cell: descriptionTextCell,
                    id: "about_cell",
                    dynamicHeight: { [weak self] containerWidth in
                        self?.descriptionTextCell.cellHeight(containerWidth: containerWidth) ?? 0
                    }
            )
        ]

        if let noteText = noteText {
            aboutSectionRows.append(noteRow(noteText: noteText))
        }

        sections.append(contentsOf: [
            Section(id: "market_section_header", footerState: .margin(height: .margin12), rows: [headerRow(title: "chart.market.header".localized)]),
            Section(id: "market_section", footerState: .margin(height: .margin12), rows: [
                StaticRow(
                        cell: marketInfoCell,
                        id: "market_cell",
                        height: MarketInfoCell.cellHeight
                )
            ]),
            Section(id: "show_markets_section", footerState: .margin(height: .margin12), rows: [
                StaticRow(
                        cell: openMarketsCell,
                        id: "show_markets_cell",
                        height: .heightSingleLineCell,
                        autoDeselect: true,
                        action: {
                            print("open markets")
                        }
                )
            ]),
            Section(id: "performance_section_header", footerState: .margin(height: .margin12), rows: [headerRow(title: "chart.performance.header".localized)]),
            Section(id: "performance_section", footerState: .margin(height: .margin12), rows: [performanceRow(weekPerformance: weekPerformance, monthPerformance: monthPerformance)]),

            Section(id: "about_section_header", rows: [headerRow(title: "chart.about.header".localized)]),
            Section(id: "about_section", footerState: .margin(height: .margin12), rows: aboutSectionRows),
        ])
        return sections
    }

    private func headerRow(title: String) -> RowProtocol {
        Row<B4Cell>(
                id: "header_cell",
                hash: title,
                height: .heightSingleLineCell,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.title = title
                    cell.selectionStyle = .none
                })
    }

    private func priceIndicatorRows() -> [RowProtocol] {
        priceIndicatorItems.enumerated().map { index, item in
            let count = priceIndicatorItems.count
            return Row<PriceIndicatorCell>(
                    id: item.range.description,
                    hash: item.range.description,
                    height: PriceIndicatorCell.cellHeight,
                    bind: { cell, _ in
                        cell.bind(viewItem: item)
                        cell.set(backgroundStyle: .lawrence, isFirst: index == 0, isLast: count - 1 == index)
                    })
        }
    }

    private func performanceRow(weekPerformance: [MultiTextMetricsView.MetricsViewItem], monthPerformance: [MultiTextMetricsView.MetricsViewItem]) -> RowProtocol {
        Row<ChartMarketPerformanceCell>(
                id: "performance_cell",
                hash: "performance_cell",
                dynamicHeight: { _ in
                    ChartMarketPerformanceCell.cellHeight(weekPerformance: weekPerformance, monthPerformance: monthPerformance)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

                    cell.bind(weekPerformance: weekPerformance, monthPerformance: monthPerformance)
                })
    }

    private func noteRow(noteText: String) -> RowProtocol {
        Row<TitledHighlightedDescriptionCell>(
                id: "note_cell",
                hash: "note_cell",
                dynamicHeight: { containerWidth in
                    TitledHighlightedDescriptionCell.height(containerWidth: containerWidth, text: noteText)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isFirst: true)

                    cell.titleIcon = UIImage(named: "warning_2_20")?.tinted(with: .themeYellowD)
                    cell.titleText = "note".localized
                    cell.descriptionText = noteText
                })
    }

}
