import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import SnapKit
import ComponentKit
import HUD
import MarketKit

class CoinDetailsViewController: ThemeViewController {
    private let viewModel: CoinDetailsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    weak var parentNavigationController: UINavigationController?

    private var viewItem: CoinDetailsViewModel.ViewItem?

    init(viewModel: CoinDetailsViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let wrapperView = UIView()

        view.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        wrapperView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        wrapperView.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        tableView.showsVerticalScrollIndicator = false

        tableView.registerCell(forClass: MarketCardCell.self)

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in
            self?.sync(viewItem: $0)
        }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }

        viewModel.onLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
    }

    private func sync(viewItem: CoinDetailsViewModel.ViewItem?) {
        self.viewItem = viewItem

        if viewItem != nil {
            tableView.isHidden = false
        } else {
            tableView.isHidden = true
        }

        tableView.reload()
    }

    private func openMajorHolders() {
        let viewController = CoinMajorHoldersModule.viewController(coinUid: viewModel.coin.uid)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openAudits(addresses: [String]) {
        let viewController = CoinAuditsModule.viewController(addresses: addresses)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openTreasuries() {
        let viewController = CoinTreasuriesModule.viewController(coin: viewModel.coin)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openFundsInvested() {
        let viewController = CoinInvestorsModule.viewController(coinUid: viewModel.coin.uid)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openReports() {
        let viewController = CoinReportsModule.viewController(coinUid: viewModel.coin.uid)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openTvl() {
        let viewController = CoinTvlModule.tvlViewController(coinUid: viewModel.coin.uid)
        parentNavigationController?.present(viewController, animated: true)
    }

    private func openTvlRank() {
        let viewController = MarketGlobalMetricModule.tvlInDefiViewController()
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openProDataChart(type: CoinProChartModule.ProChartType) {
        let viewController = CoinProChartModule.viewController(coinUid: viewModel.coin.uid, type: type)
        parentNavigationController?.present(viewController, animated: true)
    }

}

extension CoinDetailsViewController: SectionsDataSource {

    private func hasCharts(items: [MarketCardView.ViewItem?]) -> Bool {
        !items.compactMap { $0 } .isEmpty
    }

    private func liquiditySections(viewItem: CoinDetailsViewModel.ViewItem, isFirst: Bool) -> [SectionProtocol]? {
        guard hasCharts(items: [viewItem.tokenLiquidity.liquidity, viewItem.tokenLiquidity.volume]) else {
            return nil
        }

        let liquidityRow = Row<MarketCardCell>(
                id: "liquidity_chart",
                height: MarketCardView.height,
                bind: { [weak self] cell, _ in
                    cell.clear()

                    if let volumeViewItem = viewItem.tokenLiquidity.volume {
                        cell.append(viewItem: volumeViewItem) { [weak self] in
                            self?.openProDataChart(type: .volume)
                        }
                    }
                    if let liquidityViewItem = viewItem.tokenLiquidity.liquidity {
                       cell.append(viewItem: liquidityViewItem) { [weak self] in
                            self?.openProDataChart(type: .liquidity)
                        }
                    }
                }
        )

        return [
            Section(
                    id: "liquidity-header",
                    footerState: .margin(height: .margin12),
                    rows: [
                        tableView.headerInfoRow(id: "header-liquidity", title: "coin_page.token_liquidity".localized, showInfo: true, topSeparator: !isFirst) { [weak self] in
                            self?.parentNavigationController?.present(InfoModule.tokenLiquidityInfo, animated: true)
                        }
                    ]
            ),
            Section(
                    id: "liquidity",
                    footerState: .margin(height: .margin24),
                    rows: [
                        liquidityRow
                    ]
            )
        ]
    }

    private func transactionCharts(viewItem: CoinDetailsViewModel.ViewItem) -> RowProtocol {
        Row<MarketCardCell>(
                id: "transaction-charts",
                height: MarketCardView.height,
                bind: { [weak self] cell, _ in
                    cell.clear()

                    if let txCountViewItem = viewItem.tokenDistribution.txCount {
                        cell.append(viewItem: txCountViewItem) { [weak self] in
                            self?.openProDataChart(type: .txCount)
                        }
                    }
                    if let txVolumeViewItem = viewItem.tokenDistribution.txVolume {
                        cell.append(viewItem: txVolumeViewItem) { [weak self] in
                            self?.openProDataChart(type: .txVolume)
                        }
                    }
                }
        )
    }

    private func addressChart(viewItem: CoinDetailsViewModel.ViewItem) -> RowProtocol {
        Row<MarketCardCell>(
                id: "address-chart",
                height: MarketCardView.height,
                bind: { [weak self] cell, _ in
                    cell.clear()

                    if let activeAddressesViewItem = viewItem.tokenDistribution.activeAddresses {
                        cell.append(viewItem: activeAddressesViewItem) { [weak self] in
                            self?.openProDataChart(type: .activeAddresses)
                        }
                    }
                }
        )
    }

    private func distributionCharts(viewItem: CoinDetailsViewModel.ViewItem, isLast: Bool) -> [SectionProtocol] {
        let hasTxCharts = hasCharts(items: [viewItem.tokenDistribution.txCount, viewItem.tokenDistribution.txVolume])
        let hasAddresses = hasCharts(items: [viewItem.tokenDistribution.activeAddresses])

        let addressMargin: CGFloat = isLast ? .margin24 : .margin12
        let chartMargin: CGFloat = hasAddresses ? .margin8 : isLast ? .margin24 : .margin12

        var sections = [SectionProtocol]()
        guard (hasTxCharts || hasAddresses) else {
            return sections
        }

        if hasTxCharts {
            sections.append(
                    Section(
                            id: "tx-chart-section",
                            footerState: .margin(height: chartMargin),
                            rows: [
                                transactionCharts(viewItem: viewItem)
                            ]
                    )
            )
        }

        if viewItem.tokenDistribution.activeAddresses != nil {
            sections.append(
                    Section(
                            id: "address-section",
                            footerState: .margin(height: addressMargin),
                            rows: [
                                addressChart(viewItem: viewItem)
                            ]
                    )
            )
        }

        return sections
    }

    private func distributionSections(viewItem: CoinDetailsViewModel.ViewItem, isFirst: Bool) -> [SectionProtocol]? {
        var sections = distributionCharts(viewItem: viewItem, isLast: !viewItem.hasMajorHolders)

        if viewItem.hasMajorHolders {
            let majorHoldersRow = tableView.universalRow48(
                    id: "major-holders",
                    title: .subhead2("coin_page.major_holders".localized),
                    accessoryType: .disclosure,
                    isFirst: true,
                    isLast: true
            ) { [weak self] in
                self?.openMajorHolders()
            }

            sections.append(
                    Section(
                            id: "distribution",
                            footerState: .margin(height: .margin24),
                            rows: [majorHoldersRow]
                    )
            )
        }

        guard !sections.isEmpty else {
            return nil
        }

        sections.insert(
                Section(
                        id: "distribution-header",
                        footerState: .margin(height: .margin12),
                        rows: [
                            tableView.headerInfoRow(id: "header-distribution", title: "coin_page.token_distribution".localized, showInfo: true, topSeparator: !isFirst) { [weak self] in
                                self?.parentNavigationController?.present(InfoModule.tokenDistributionInfo, animated: true)
                            }
                        ]
                ),
                at: 0
        )

        return sections
    }

    private func tvlSections(viewItem: CoinDetailsViewModel.ViewItem) -> [SectionProtocol]? {
        guard let tvlChart = viewItem.tvlChart else {
            return nil
        }

        let tvlRow = Row<MarketCardCell>(
                id: "tvl_chart",
                height: MarketCardView.height,
                bind: { [weak self] cell, _ in
                    cell.clear()

                    let view = MarketCardView()
                    view.set(viewItem: tvlChart)
                    view.onTap = { [weak self] in
                        self?.openTvl()
                    }
                    cell.append(view: view)
                }
        )

        var sections: [SectionProtocol] = [
            Section(
                    id: "tvl-header",
                    footerState: .margin(height: .margin12),
                    rows: [
                        tableView.headerInfoRow(id: "header-tvl", title: "coin_page.token_tvl".localized, showInfo: true) { [weak self] in
                            self?.parentNavigationController?.present(InfoModule.tokenTvlInfo, animated: true)
                        }
                    ]
            ),
            Section(
                    id: "tvl",
                    footerState: .margin(height: .margin12),
                    rows: [
                        tvlRow
                    ]
            )
        ]

        var rows = [RowProtocol]()

        let hasRank = viewItem.tvlRank != nil
        let hasRatio = viewItem.tvlRatio != nil

        if let tvlRank = viewItem.tvlRank {
            let tvlRankRow = tableView.universalRow48(
                    id: "market-cap-tvl-rank",
                    title: .subhead2("coin_page.tvl_rank".localized),
                    value: .subhead1(tvlRank),
                    accessoryType: .disclosure,
                    isFirst: true,
                    isLast: !hasRatio,
                    action: { [weak self] in
                        self?.openTvlRank()
                    }
            )

            rows.append(tvlRankRow)
        }

        if let tvlRatio = viewItem.tvlRatio {
            let tvlRatioRow = tableView.universalRow48(
                    id: "market-cap-tvl-ratio",
                    title: .subhead2("coin_page.market_cap_tvl_ratio".localized),
                    value: .subhead1(tvlRatio),
                    isFirst: !hasRank,
                    isLast: true
            )

            rows.append(tvlRatioRow)
        }

        sections.append(Section(
                id: "tvl-info",
                footerState: .margin(height: rows.isEmpty ? .margin12 : .margin24),
                rows: rows
        ))

        return sections
    }

    private func investorDataSections(viewItem: CoinDetailsViewModel.ViewItem, isFirst: Bool) -> [SectionProtocol]? {
        let treasuries = viewItem.treasuries
        let fundsInvested = viewItem.fundsInvested
        let reportsCount = viewItem.reportsCount

        var rows = [RowProtocol]()

        let count = [treasuries, fundsInvested, reportsCount].compactMap { $0 }.count

        if let treasuries {
            let row = tableView.universalRow48(
                    id: "treasuries",
                    title: .subhead2("coin_page.treasuries".localized),
                    value: .subhead1(treasuries),
                    accessoryType: .disclosure,
                    isFirst: true,
                    isLast: rows.count == count - 1
            ) { [weak self] in
                self?.openTreasuries()
            }

            rows.append(row)
        }

        if let fundsInvested {
            let row = tableView.universalRow48(
                    id: "funds-invested",
                    title: .subhead2("coin_page.funds_invested".localized),
                    value: .subhead1(fundsInvested),
                    accessoryType: .disclosure,
                    isFirst: rows.isEmpty,
                    isLast: rows.count == count - 1
            ) { [weak self] in
                self?.openFundsInvested()
            }

            rows.append(row)
        }

        if let reportsCount {
            let row = tableView.universalRow48(
                    id: "reports",
                    title: .subhead2("coin_page.reports".localized),
                    value: .subhead1(reportsCount),
                    accessoryType: .disclosure,
                    isFirst: rows.isEmpty,
                    isLast: rows.count == count - 1
            ) { [weak self] in
                self?.openReports()
            }

            rows.append(row)
        }

        if rows.isEmpty {
            return nil
        } else {
            return [
                Section(
                        id: "investor-data-header",
                        footerState: .margin(height: .margin12),
                        rows: [
                            tableView.headerInfoRow(id: "header-investor-data", title: "coin_page.investor_data".localized, topSeparator: !isFirst)
                        ]
                ),
                Section(
                        id: "investor-data",
                        footerState: .margin(height: .margin24),
                        rows: rows
                )
            ]
        }
    }

    private func securitySections(viewItem: CoinDetailsViewModel.ViewItem) -> [SectionProtocol]? {
        let securityViewItems = viewItem.securityViewItems
        let auditAddresses = viewItem.auditAddresses

        var rows = [RowProtocol]()

        let hasSecurity = !securityViewItems.isEmpty
        let hasAudits = !auditAddresses.isEmpty

        for (index, viewItem) in securityViewItems.enumerated() {
            let row = tableView.universalRow48(
                id: "security-\(viewItem.type)",
                title: .subhead2(viewItem.type.title),
                value: .custom(viewItem.value, .subhead1, viewItem.valueGrade.textColor),
                isFirst: index == 0,
                isLast: index == securityViewItems.count - 1 && !hasAudits
            )

            rows.append(row)
        }

        if !auditAddresses.isEmpty {
            let row = tableView.universalRow48(
                id: "audits",
                title: .subhead2("coin_page.audits".localized),
                accessoryType: .disclosure,
                isFirst: !hasSecurity,
                isLast: true
            ) { [weak self] in
                self?.openAudits(addresses: auditAddresses)
            }

            rows.append(row)
        }

        if rows.isEmpty {
            return nil
        } else {
            return [
                Section(
                        id: "security-parameters-header",
                        footerState: .margin(height: .margin12),
                        rows: [
                            tableView.headerInfoRow(id: "header-security-parameters", title: "coin_page.security_parameters".localized, showInfo: true) { [weak self] in
                                self?.parentNavigationController?.present(InfoModule.securityParametersInfo, animated: true)
                            }
                        ]
                ),
                Section(
                        id: "security-parameters",
                        footerState: .margin(height: .margin24),
                        rows: rows
                )
            ]
        }
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem = viewItem {
            if let liquiditySections = liquiditySections(viewItem: viewItem, isFirst: sections.isEmpty) {
                sections.append(contentsOf: liquiditySections)
            }

            if let distributionSections = distributionSections(viewItem: viewItem, isFirst: sections.isEmpty) {
                sections.append(contentsOf: distributionSections)
            }

            if let tvlSections = tvlSections(viewItem: viewItem) {
                sections.append(contentsOf: tvlSections)
            }

            if let investorDataSections = investorDataSections(viewItem: viewItem, isFirst: sections.isEmpty) {
                sections.append(contentsOf: investorDataSections)
            }

            if let securitySections = securitySections(viewItem: viewItem) {
                sections.append(contentsOf: securitySections)
            }
        }

        return sections
    }

}

extension CoinDetailsViewModel.SecurityGrade {

    var textColor: UIColor {
        switch self {
        case .low: return .themeLucian
        case .medium: return .themeIssykBlue
        case .high: return .themeRemus
        }
    }

}
