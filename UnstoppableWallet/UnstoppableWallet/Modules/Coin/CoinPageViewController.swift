import UIKit
import XRatesKit
import RxSwift
import ThemeKit
import SectionsTableView
import SnapKit
import HUD
import Chart
import ComponentKit
import Down
import CoinKit

class CoinPageViewController: ThemeViewController {
    private let viewModel: CoinPageViewModel
    private let chartViewModel: CoinChartViewModel
    private let favoriteViewModel: CoinFavoriteViewModel
//    private let priceAlertViewModel: CoinPriceAlertViewModel
    private let markdownParser: CoinPageMarkdownParser
    private var urlManager: IUrlManager
    private let disposeBag = DisposeBag()

    private var state: CoinPageViewModel.State = .loading

    private var favoriteButtonItem: UIBarButtonItem?
    private var alertButtonItem: UIBarButtonItem?

    private let tableView = SectionsTableView(style: .grouped)
    private let subtitleCell = A7Cell()

    /* Chart section */
    private let currentRateCell: CoinChartRateCell

    private let chartIntervalAndSelectedRateCell = ChartIntervalAndSelectedRateCell()
    private let intervalRow: StaticRow

    private let chartViewCell: ChartViewCell
    private let chartRow: StaticRow

    private let indicatorSelectorCell = IndicatorSelectorCell()

    /* Description */
    private let descriptionTextCell = ReadMoreTextCell()

    init(viewModel: CoinPageViewModel, favoriteViewModel: CoinFavoriteViewModel, chartViewModel: CoinChartViewModel, configuration: ChartConfiguration, markdownParser: CoinPageMarkdownParser, urlManager: IUrlManager) {
        self.viewModel = viewModel
        self.favoriteViewModel = favoriteViewModel
//        self.priceAlertViewModel = priceAlertViewModel
        self.chartViewModel = chartViewModel
        self.markdownParser = markdownParser
        self.urlManager = urlManager

        currentRateCell = CoinChartRateCell(viewModel: chartViewModel)

        intervalRow = StaticRow(
                cell: chartIntervalAndSelectedRateCell,
                id: "chartIntervalAndSelectedRate",
                height: .heightSingleLineCell
        )

        chartViewCell = ChartViewCell(configuration: configuration)
        chartRow = StaticRow(
                cell: chartViewCell,
                id: "chartView",
                height: ChartViewCell.cellHeight
        )

        super.init()

        chartViewCell.delegate = chartViewModel

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapCloseButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        title = viewModel.title

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false

        tableView.registerCell(forClass: A1Cell.self)
        tableView.registerCell(forClass: BCell.self)
        tableView.registerCell(forClass: B4Cell.self)
        tableView.registerCell(forClass: D1Cell.self)
        tableView.registerCell(forClass: D2Cell.self)
        tableView.registerCell(forClass: D6Cell.self)
        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: DB7Cell.self)
        tableView.registerCell(forClass: D9Cell.self)
        tableView.registerCell(forClass: D20Cell.self)
        tableView.registerCell(forClass: ReturnOfInvestmentsTableViewCell.self)
        tableView.registerCell(forClass: ChartMarketPerformanceCell.self)
        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: ErrorCell.self)
        tableView.registerCell(forClass: TextCell.self)

        chartIntervalAndSelectedRateCell.bind(filters: chartViewModel.chartTypes.map {
            .item(title: $0)
        })
        chartIntervalAndSelectedRateCell.onSelectInterval = { [weak self] index in
            self?.chartViewModel.onSelectType(at: index)
        }

        indicatorSelectorCell.onTapIndicator = { [weak self] indicator in
            self?.chartViewModel.onTap(indicator: indicator)
        }

        descriptionTextCell.set(backgroundStyle: .transparent, isFirst: true)
        descriptionTextCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }

        subtitleCell.set(backgroundStyle: .transparent, isFirst: true)
        subtitleCell.title = viewModel.subtitle
        subtitleCell.titleColor = .themeGray
        subtitleCell.titleImage = .image(coinType: viewModel.coinType)
        subtitleCell.set(titleImageSize: .iconSize24)
        subtitleCell.valueColor = .themeGray
        subtitleCell.selectionStyle = .none

        tableView.buildSections()

        subscribeViewModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

    private func subscribeViewModels() {
        // barItems section
//        subscribe(disposeBag, priceAlertViewModel.priceAlertActiveDriver) { [weak self] in self?.sync(priceAlertEnabled: $0) }
        subscribe(disposeBag, favoriteViewModel.favoriteDriver) { [weak self] in self?.sync(favorite: $0) }
        subscribe(disposeBag, favoriteViewModel.favoriteHudSignal) { [weak self] in self?.showHud(title: $0) }

        // page section
        subscribe(disposeBag, viewModel.stateDriver) { [weak self] in self?.sync(state: $0) }

        // chart section
        intervalRow.onReady = { [weak self] in self?.subscribeToInterval() }
        chartRow.onReady = { [weak self] in self?.subscribeToChart() }
    }

    private func subscribeToInterval() {
        subscribe(disposeBag, chartViewModel.pointSelectModeEnabledDriver) { [weak self] in self?.syncChart(selected: $0) }
        subscribe(disposeBag, chartViewModel.pointSelectedItemDriver) { [weak self] in self?.syncChart(selectedViewItem: $0) }
        subscribe(disposeBag, chartViewModel.chartTypeIndexDriver) { [weak self] in self?.syncChart(typeIndex: $0) }
    }

    private func subscribeToChart() {
        subscribe(disposeBag, chartViewModel.loadingDriver) { [weak self] in self?.syncChart(loading: $0) }
        subscribe(disposeBag, chartViewModel.errorDriver) { [weak self] in self?.syncChart(error: $0) }
        subscribe(disposeBag, chartViewModel.chartInfoDriver) { [weak self] in self?.syncChart(viewItem: $0) }
    }

    private func syncBarButtons() {
        navigationItem.rightBarButtonItems = [favoriteButtonItem, alertButtonItem].compactMap { $0 }
    }

    @objc private func onAlertTap() {
//        guard let chartNotificationViewController = ChartNotificationRouter.module(
//                coinType: priceAlertViewModel.coinType,
//                coinTitle: viewModel.coinTitle,
//                mode: .all) else {
//
//            return
//        }
//
//        present(chartNotificationViewController, animated: true)
    }

    @objc private func onFavoriteTap() {
        favoriteViewModel.favorite()
    }

    @objc private func onUnfavoriteTap() {
        favoriteViewModel.unfavorite()
    }

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

}

extension CoinPageViewController {

    // BarItems section

    private func sync(priceAlertEnabled: Bool) {
//        guard priceAlertViewModel.alertNotificationEnabled == true else {
//            alertButtonItem = nil
//            syncBarButtons()
//
//            return
//        }
//
//        var image: UIImage?
//        var imageTintColor: UIColor?
//        if priceAlertEnabled {
//            image = UIImage(named: "bell_ring_24")?.withRenderingMode(.alwaysTemplate)
//            imageTintColor = .themeJacob
//        } else {
//            image = UIImage(named: "bell_24")?.withRenderingMode(.alwaysTemplate)
//            imageTintColor = .themeGray
//        }
//
//        alertButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(onAlertTap))
//        alertButtonItem?.tintColor = imageTintColor
//
//        syncBarButtons()
    }

    private func sync(favorite: Bool) {
        let selector = favorite ? #selector(onUnfavoriteTap) : #selector(onFavoriteTap)
        let color = favorite ? UIColor.themeJacob : UIColor.themeGray

        let favoriteImage = UIImage(named: "rate_24")?.withRenderingMode(.alwaysTemplate)
        favoriteButtonItem = UIBarButtonItem(image: favoriteImage, style: .plain, target: self, action: selector)
        favoriteButtonItem?.tintColor = color

        syncBarButtons()
    }

    private func showHud(title: String) {
        HudHelper.instance.showSuccess(title: title)
    }

    // Page section

    private func sync(state: CoinPageViewModel.State) {
        switch state {
        case .loaded(let viewItem): subtitleCell.value = viewItem.marketInfo.marketCapRank
        default: subtitleCell.value = nil
        }

        self.state = state
        tableView.reload()
    }

    // Chart section

    private func deactivateIndicators() {
        ChartIndicatorSet.all.forEach { indicator in
            indicatorSelectorCell.set(indicator: indicator, selected: false)
            indicatorSelectorCell.set(indicator: indicator, disabled: true)
        }
    }

    private func syncChart(viewItem: CoinChartViewModel.ViewItem?) {
        guard let viewItem = viewItem else {
            return
        }

        chartViewCell.set(
                data: viewItem.chartData,
                trend: viewItem.chartTrend,
                min: viewItem.minValue,
                max: viewItem.maxValue,
                timeline: viewItem.timeline)

        guard let selectedIndicator = viewItem.selectedIndicator else {
            chartViewCell.setVolumes(hidden: true, limitHidden: false)
            ChartIndicatorSet.all.forEach { indicator in
                chartViewCell.bind(indicator: indicator, hidden: true)
            }
            deactivateIndicators()

            return
        }

        chartViewCell.setVolumes(hidden: selectedIndicator.hideVolumes, limitHidden: selectedIndicator.hideVolumes)

        ChartIndicatorSet.all.forEach { indicator in
            let show = selectedIndicator.contains(indicator)

            chartViewCell.bind(indicator: indicator, hidden: !show)

            indicatorSelectorCell.set(indicator: indicator, disabled: false)
            indicatorSelectorCell.set(indicator: indicator, selected: show)
        }
    }

    private func syncChart(selected: Bool) {
        chartIntervalAndSelectedRateCell.bind(displayMode: selected ? .selectedRate : .interval)
    }

    private func syncChart(selectedViewItem: SelectedPointViewItem?) {
        guard let viewItem = selectedViewItem else {
            return
        }
        chartIntervalAndSelectedRateCell.bind(selectedPointViewItem: viewItem)
    }

    private func syncChart(typeIndex: Int) {
        chartIntervalAndSelectedRateCell.select(index: typeIndex)
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
                rows: [
                    StaticRow(
                            cell: subtitleCell,
                            id: "subtitle",
                            height: .heightCell48
                    )
                ]
        )
    }

    private var chartSection: SectionProtocol {
        Section(
                id: "chart",
                rows: [
                    StaticRow(
                            cell: currentRateCell,
                            id: "currentRate",
                            height: ChartCurrentRateCell.cellHeight
                    ),
                    intervalRow,
                    chartRow,
                    StaticRow(
                            cell: indicatorSelectorCell,
                            id: "indicatorSelector",
                            height: .heightSingleLineCell
                    )
                ])
    }

    private func headerRow(title: String) -> RowProtocol {
        Row<BCell>(
                id: "header_cell_\(title)",
                hash: title,
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.selectionStyle = .none
                    cell.title = title
                }
        )
    }

    private func descriptionSection(description: CoinMetaDescriptionType) -> SectionProtocol {
        var rows: [RowProtocol] = [
            headerRow(title: "chart.about.header".localized)
        ]

        let markdownText: String
        switch description {
        case let .html(text):
            markdownText = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        case let .markdown(text):
            markdownText = text
        }

        descriptionTextCell.contentText = try? markdownParser.attributedString(from: markdownText)
        rows.append(
                StaticRow(
                        cell: descriptionTextCell,
                        id: "about_cell",
                        dynamicHeight: { [weak self] containerWidth in
                            self?.descriptionTextCell.cellHeight(containerWidth: containerWidth) ?? 0
                        }
                ))

        return Section(
                id: "description",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func linksSection(guideUrl: URL?, links: [CoinPageViewModel.Link]) -> SectionProtocol {
        var guideRows = [RowProtocol]()

        if let guideUrl = guideUrl {
            let isLast = links.isEmpty

            let guideRow = Row<A1Cell>(
                    id: "guide",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: isLast)
                        cell.titleImage = UIImage(named: "academy_1_20")
                        cell.title = "coin_page.guide".localized
                    },
                    action: { [weak self] _ in
                        let module = MarkdownModule.viewController(url: guideUrl)
                        self?.navigationController?.pushViewController(module, animated: true)
                    }
            )

            guideRows.append(guideRow)
        }

        return Section(
                id: "links",
                headerState: .margin(height: .margin12),
                rows: guideRows + links.enumerated().map { index, link in
                    let isFirst = guideRows.isEmpty && index == 0
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
        switch link.type {
        case .twitter:
            let account = link.url.stripping(prefix: "https://twitter.com/")

            if let appUrl = URL(string: "twitter://user?screen_name=\(account)"), UIApplication.shared.canOpenURL(appUrl) {
                UIApplication.shared.open(appUrl)
            } else {
                urlManager.open(url: link.url, from: self)
            }
        default:
            urlManager.open(url: link.url, from: self)
        }
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

    private func marketsSection(marketInfo: CoinPageViewModel.MarketInfo, tickers: [MarketTicker]) -> SectionProtocol? {
        var rows = [RowProtocol]()

        let hasVolume = marketInfo.volume24h != nil
        let hasMarkets = !tickers.isEmpty

        if let volume = marketInfo.volume24h {
            let tradingVolumeRow = Row<D6Cell>(
                    id: "trading-volume",
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: !hasMarkets)
                        cell.title = "coin_page.trading_volume".localized
                        cell.value = volume
                        cell.valueColor = .themeOz
                        cell.valueImage = UIImage(named: "chart_20")
                        cell.valueImageTintColor = .themeGray
                    },
                    action: { [weak self] _ in
                        self?.openTradingVolume()
                    }
            )

            rows.append(tradingVolumeRow)
        }

        if !tickers.isEmpty {
            let marketsRow = Row<D1Cell>(
                    id: "markets",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: !hasVolume, isLast: true)
                        cell.title = "coin_page.markets".localized
                    },
                    action: { [weak self] _ in
                        self?.openMarkets(tickers: tickers)
                    }
            )

            rows.append(marketsRow)
        }

        if !rows.isEmpty {
            return Section(id: "markets", headerState: .margin(height: .margin12), rows: rows)
        } else {
            return nil
        }
    }

    private func tvlSection(marketInfo: CoinPageViewModel.MarketInfo) -> SectionProtocol? {
        guard let tvl = marketInfo.tvl else {
            return nil
        }

        let hasRank = marketInfo.tvlRank != nil
        let hasRatio = marketInfo.tvlRatio != nil

        let tvlRow = Row<D6Cell>(
                id: "tvl_chart",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: !hasRatio && !hasRank)
                    cell.title = "coin_page.tvl".localized
                    cell.value = tvl
                    cell.valueColor = .themeOz
                    cell.valueImage = UIImage(named: "chart_20")
                    cell.valueImageTintColor = .themeGray
                },
                action: { [weak self] _ in
                    self?.openTvl()
                }
        )

        var rows: [RowProtocol] = [tvlRow]

        if let tvlRank = marketInfo.tvlRank {
            let tvlRankRow = Row<D2Cell>(
                    id: "market-cap-tvl-rank",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: false, isLast: !hasRatio)
                        cell.title = "coin_page.tvl_rank".localized
                        cell.value = tvlRank
                        cell.valueColor = .themeOz
                    },
                    action: { [weak self] _ in
                        self?.openTvlRank()
                    }
            )

            rows.append(tvlRankRow)
        }


        if let marketCapTvlRatio = marketInfo.tvlRatio {
            let marketCapTvlRatioRow = Row<D7Cell>(
                    id: "market-cap-tvl-ratio",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
                        cell.title = "coin_page.market_cap_tvl_ratio".localized
                        cell.value = marketCapTvlRatio
                    }
            )

            rows.append(marketCapTvlRatioRow)
        }

        return Section(id: "markets", headerState: .margin(height: .margin12), rows: rows)
    }

    private func openMarkets(tickers: [MarketTicker]) {
        let viewController = CoinMarketsModule.viewController(coinCode: viewModel.coinCode, coinType: viewModel.coinType, tickers: tickers)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openMajorHolders(coinType: CoinType) {
        let viewController = CoinMajorHoldersModule.viewController(coinType: coinType)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openAudits(coinType: CoinType) {
        let viewController = CoinAuditsModule.viewController(coinType: coinType)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openSecurityInfo(type: CoinPageViewModel.SecurityType) {
        let viewController = CoinPageInfoViewController(header: type.title, viewItems: viewModel.securityInfoViewItems(type: type))
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func openFundsInvested(fundCategories: [CoinFundCategory]) {
        let viewController = CoinInvestorsModule.viewController(fundCategories: fundCategories)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openTvl() {
        let viewController = CoinTvlModule.viewController(coinType: viewModel.coinType)
        present(viewController, animated: true)
    }

    private func openTvlRank() {
        let viewController = CoinTvlRankModule.viewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openTradingVolume() {
        let viewController = CoinTradingVolumeModule.viewController(coinType: viewModel.coinType, coinTitle: viewModel.coinTitle)
        present(viewController, animated: true)
    }

    private func returnOfInvestmentsSection(viewItems: [[CoinPageViewModel.ReturnOfInvestmentsViewItem]]) -> SectionProtocol {
        Section(
                id: "return_of_investments_section",
                headerState: .margin(height: .margin12),
                rows: [
                    Row<ReturnOfInvestmentsTableViewCell>(
                            id: "return_of_investments_cell",
                            dynamicHeight: { _ in
                                ReturnOfInvestmentsTableViewCell.height(viewItems: viewItems)
                            },
                            bind: { cell, _ in
                                cell.bind(viewItems: viewItems)
                            }
                    )
                ]
        )
    }

    private func categoriesSection(categories: [String]) -> SectionProtocol {
        let text = categories.joined(separator: ", ")

        return Section(
                id: "categories",
                headerState: .margin(height: .margin12),
                rows: [
                    headerRow(title: "coin_page.category".localized),
                    Row<TextCell>(
                            id: "categories",
                            dynamicHeight: { width in
                                TextCell.height(containerWidth: width, text: text)
                            },
                            bind: { cell, _ in
                                cell.contentText = text
                            }
                    )
                ]
        )
    }

    private func investorDataSections(majorHoldersCoinType: CoinType?, fundCategories: [CoinFundCategory]) -> [SectionProtocol] {
        var rows = [RowProtocol]()

        let hasMajorHolders = majorHoldersCoinType != nil
        let hasFunds = !fundCategories.isEmpty

        if let coinType = majorHoldersCoinType {
            let row = Row<D1Cell>(
                    id: "major-holders",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: !hasFunds)
                        cell.title = "coin_page.major_holders".localized
                    },
                    action: { [weak self] _ in
                        self?.openMajorHolders(coinType: coinType)
                    }
            )

            rows.append(row)
        }

        if !fundCategories.isEmpty {
            let fundsInvestedRow = Row<D2Cell>(
                    id: "funds-invested",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: !hasMajorHolders, isLast: true)
                        cell.title = "coin_page.funds_invested".localized
                    },
                    action: { [weak self] _ in
                        self?.openFundsInvested(fundCategories: fundCategories)
                    }
            )

            rows.append(fundsInvestedRow)
        }

        if rows.isEmpty {
            return []
        } else {
            return [
                Section(
                        id: "investor-data-header",
                        headerState: .margin(height: .margin12),
                        footerState: .margin(height: .margin12),
                        rows: [
                            headerRow(title: "coin_page.investor_data".localized)
                        ]
                ),
                Section(id: "investor-data", rows: rows)
            ]
        }
    }

    private func securitySections(securityViewItems: [CoinPageViewModel.SecurityViewItem], auditsCoinType: CoinType?) -> [SectionProtocol] {
        var rows = [RowProtocol]()

        let hasSecurity = !securityViewItems.isEmpty
        let hasAudits = auditsCoinType != nil

        for (index, viewItem) in securityViewItems.enumerated() {
            let row = Row<D20Cell>(
                    id: "security-\(viewItem.type)",
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: index == 0, isLast: index == securityViewItems.count - 1 && !hasAudits)
                        cell.title = viewItem.type.title
                        cell.value = viewItem.value
                        cell.valueBackground = viewItem.valueColor
                        cell.image = UIImage(named: "circle_information_20")
                    },
                    action: { [weak self] _ in
                        self?.openSecurityInfo(type: viewItem.type)
                    }
            )

            rows.append(row)
        }

        if let auditsCoinType = auditsCoinType {
            let row = Row<D1Cell>(
                    id: "audits",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: !hasSecurity, isLast: true)
                        cell.title = "coin_page.audits".localized
                    },
                    action: { [weak self] _ in
                        self?.openAudits(coinType: auditsCoinType)
                    }
            )

            rows.append(row)
        }

        if rows.isEmpty {
            return []
        } else {
            return [
                Section(
                        id: "security-parameters-header",
                        headerState: .margin(height: .margin12),
                        footerState: .margin(height: .margin12),
                        rows: [
                            headerRow(title: "coin_page.security_parameters".localized)
                        ]
                ),
                Section(id: "security-parameters", rows: rows)
            ]
        }
    }

    private func contractInfoSection(contractInfo: CoinPageViewModel.ContractInfo) -> SectionProtocol {
        Section(
                id: "contract-info",
                headerState: .margin(height: .margin12),
                rows: [
                    Row<D9Cell>(
                            id: "contract-info",
                            height: .heightCell48,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                cell.title = contractInfo.title
                                cell.viewItem = .init(type: .raw, value: { contractInfo.value })
                            }
                    )
                ]
        )
    }

    private func marketRow(id: String, title: String, badge: String?, text: String, isFirst: Bool, isLast: Bool) -> RowProtocol {
        if let badge = badge {
            return Row<DB7Cell>(
                    id: id,
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                        cell.title = title
                        cell.titleBadgeText = badge
                        cell.value = text
                    }
            )
        } else {
            return Row<D7Cell>(
                    id: id,
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                        cell.title = title
                        cell.value = text
                    }
            )
        }
    }

    private func marketInfoSection(marketInfo: CoinPageViewModel.MarketInfo) -> SectionProtocol? {
        let datas = [
            marketInfo.marketCap.map {
                (id: "market_cap", title: "coin_page.market_cap".localized, badge: marketInfo.marketCapRank, text: $0)
            },
            marketInfo.circulatingSupply.map {
                (id: "circulating_supply", title: "coin_page.circulating_supply".localized, badge: nil, text: $0)
            },
            marketInfo.totalSupply.map {
                (id: "total_supply", title: "coin_page.total_supply".localized, badge: nil, text: $0)
            },
            marketInfo.dilutedMarketCap.map {
                (id: "dilluted_m_cap", title: "coin_page.dilluted_market_cap".localized, badge: nil, text: $0)
            },
            marketInfo.genesisDate.map {
                (id: "genesis_date", title: "coin_page.genesis_date".localized, badge: nil, text: $0)
            }
        ].compactMap {
            $0
        }

        guard !datas.isEmpty else {
            return nil
        }

        let rows = datas.enumerated().map { index, tuple in
            marketRow(
                    id: tuple.id,
                    title: tuple.title,
                    badge: tuple.badge,
                    text: tuple.text,
                    isFirst: index == 0,
                    isLast: index == datas.count - 1
            )
        }


        return Section(
                id: "market_info_section",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private var spinnerSection: SectionProtocol {
        Section(
                id: "spinner",
                rows: [
                    Row<SpinnerCell>(
                            id: "spinner",
                            height: 100
                    )
                ]
        )
    }

    private func errorSection(text: String) -> SectionProtocol {
        Section(
                id: "error",
                rows: [
                    Row<ErrorCell>(
                            id: "error",
                            dynamicHeight: { _ in
                                100 // todo: calculate height in ErrorCell
                            },
                            bind: { cell, _ in
                                cell.errorText = text
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

        switch state {
        case .loading:
            sections.append(spinnerSection)

        case .loaded(let viewItem):
            sections.append(returnOfInvestmentsSection(viewItems: viewItem.returnOfInvestmentsViewItems))

            if let marketInfoSection = marketInfoSection(marketInfo: viewItem.marketInfo) {
                sections.append(marketInfoSection)
            }

            if let marketsSection = marketsSection(marketInfo: viewItem.marketInfo, tickers: viewItem.tickers) {
                sections.append(marketsSection)
            }

            if let tvlSection = tvlSection(marketInfo: viewItem.marketInfo) {
                sections.append(tvlSection)
            }

            sections.append(contentsOf: investorDataSections(majorHoldersCoinType: viewItem.majorHoldersCoinType, fundCategories: viewItem.fundCategories))

            sections.append(contentsOf: securitySections(securityViewItems: viewItem.securities, auditsCoinType: viewItem.auditsCoinType))

            if let categories = viewItem.categories {
                sections.append(categoriesSection(categories: categories))
            }

            if !viewItem.description.description.isEmpty {
                sections.append(descriptionSection(description: viewItem.description))
            }

            if let contractInfo = viewItem.contractInfo {
                sections.append(contractInfoSection(contractInfo: contractInfo))
            }

            if viewItem.guideUrl != nil || !viewItem.links.isEmpty {
                sections.append(linksSection(guideUrl: viewItem.guideUrl, links: viewItem.links))
            }

            sections.append(poweredBySection(text: "Powered by CoinGecko API"))

        case .failed(let error):
            sections.append(errorSection(text: error))
        }

        return sections
    }

}
