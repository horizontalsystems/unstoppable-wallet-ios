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
    private let proFeaturesViewModel: ProFeaturesYakAuthorizationViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderView()
    private let proFeaturesCell: ProFeaturesPassesCell

    weak var parentNavigationController: UINavigationController?

    private var viewItem: CoinDetailsViewModel.ViewItem?

    init(viewModel: CoinDetailsViewModel, proFeaturesViewModel: ProFeaturesYakAuthorizationViewModel) {
        self.viewModel = viewModel
        self.proFeaturesViewModel = proFeaturesViewModel

        proFeaturesCell = ProFeaturesPassesCell(viewModel: proFeaturesViewModel)
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

        errorView.configureSyncError(target: self, action: #selector(onRetry))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        tableView.showsVerticalScrollIndicator = false

        tableView.registerCell(forClass: BCell.self)
        tableView.registerCell(forClass: D1Cell.self)
        tableView.registerCell(forClass: D2Cell.self)
        tableView.registerCell(forClass: D6Cell.self)
        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: CoinDetailsMetricCell.self)

        proFeaturesCell.parentViewController = parentNavigationController

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

    private func openSecurityInfo(type: CoinDetailsViewModel.SecurityType) {
        let viewController = CoinPageInfoViewController(header: type.title, viewItems: viewModel.securityInfoViewItems(type: type))
        parentNavigationController?.present(ThemeNavigationController(rootViewController: viewController), animated: true)
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

    private func openProDataChart(proFeaturesActivated: Bool, type: CoinProChartModule.ProChartType) {
        guard proFeaturesActivated else {
            proFeaturesViewModel.authorize()
            return
        }

        // todo: Route pro charts.
        let viewController = CoinProChartModule.viewController(coinUid: viewModel.coin.uid, type: type)
        parentNavigationController?.present(viewController, animated: true)
    }

}

extension CoinDetailsViewController: IProFeaturesLockDelegate {

    func onGoToMint(viewController: UIViewController) {
        viewController.dismiss(animated: true) {
            print("Can open main mint controller!")
        }
    }

}

extension CoinDetailsViewController: SectionsDataSource {

    private func headerRow(title: String, topSeparator: Bool = true) -> RowProtocol {
        Row<BCell>(
                id: "header_cell_\(title)",
                hash: title,
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isFirst: !topSeparator)
                    cell.selectionStyle = .none
                    cell.title = title
                }
        )
    }

    private func proFeaturesPassesSection(viewItem: CoinDetailsViewModel.ViewItem) -> SectionProtocol? {
        guard !viewItem.proFeaturesActivated else {
            return nil
        }

        return Section(
                id: "pro-features-passes-section",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin12),
                rows: [
                    StaticRow(
                            cell: proFeaturesCell,
                            id: "pro-features-passes",
                            height: ProFeaturesPassesCell.height
                    )
                ]
        )
    }

    private func hasCharts(items: [CoinDetailsViewModel.ChartViewItem?]) -> Bool {
        !items.compactMap { $0 } .isEmpty
    }

    private func liquiditySections(viewItem: CoinDetailsViewModel.ViewItem, isFirst: Bool) -> [SectionProtocol]? {
        guard hasCharts(items: [viewItem.tokenLiquidity.liquidity, viewItem.tokenLiquidity.volume]) else {
            return nil
        }

        let liquidityRow = Row<CoinDetailsMetricCell>(
                id: "liquidity_chart",
                height: CoinDetailsMetricCell.cellHeight,
                bind: { [weak self] cell, _ in
                    cell.clear()
                    cell.set(configuration: .smallChart)

                    if let volumeViewItem = viewItem.tokenLiquidity.volume {
                        cell.append(viewItem: volumeViewItem) { [weak self] in
                            self?.openProDataChart(proFeaturesActivated: viewItem.proFeaturesActivated, type: .volume)
                        }
                        cell.set(title: CoinProChartModule.ProChartType.volume.title)
                    }
                    if let liquidityViewItem = viewItem.tokenLiquidity.liquidity {
                        cell.append(viewItem: liquidityViewItem) { [weak self] in
                            self?.openProDataChart(proFeaturesActivated: viewItem.proFeaturesActivated, type: .liquidity)
                        }
                        cell.set(title: CoinProChartModule.ProChartType.liquidity.title)
                    }
                }
        )

        return [
            Section(
                    id: "liquidity-header",
                    footerState: .margin(height: .margin12),
                    rows: [
                        headerRow(title: "coin_page.token_liquidity".localized, topSeparator: !isFirst),
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

    private func distributionCharts(viewItem: CoinDetailsViewModel.ViewItem) -> [RowProtocol] {
        let hasTxCharts = hasCharts(items: [viewItem.tokenDistribution.txCount, viewItem.tokenDistribution.txVolume])
        let hasAddresses = hasCharts(items: [viewItem.tokenDistribution.activeAddresses])
        let tightMargin: CGFloat = hasAddresses ? .margin8 : .margin12

        var rows = [RowProtocol]()
        guard (hasTxCharts || hasAddresses) else {
            return rows
        }

        if hasTxCharts {
            rows.append(
                    Row<CoinDetailsMetricCell>(
                            id: "transaction-charts",
                            height: CoinDetailsMetricCell.cellHeight + tightMargin,
                            bind: { [weak self] cell, _ in
                                cell.clear()
                                cell.set(configuration: .smallChart)

                                if let txCountViewItem = viewItem.tokenDistribution.txCount {
                                    cell.append(viewItem: txCountViewItem) { [weak self] in
                                        self?.openProDataChart(proFeaturesActivated: viewItem.proFeaturesActivated, type: .txCount)
                                    }
                                    cell.set(title: CoinProChartModule.ProChartType.txCount.title)
                                }
                                if let txVolumeViewItem = viewItem.tokenDistribution.txVolume {
                                    cell.append(viewItem: txVolumeViewItem) { [weak self] in
                                        self?.openProDataChart(proFeaturesActivated: viewItem.proFeaturesActivated, type: .txVolume)
                                    }
                                    cell.set(title: CoinProChartModule.ProChartType.txVolume.title)
                                }

                            }
                    )
            )
        }

        if let activeAddressesViewItem = viewItem.tokenDistribution.activeAddresses {
            rows.append(
                    Row<CoinDetailsMetricCell>(
                            id: "addresses-charts",
                            height: CoinDetailsMetricCell.cellHeight + .margin12,
                            bind: { [weak self] cell, _ in
                                cell.clear()
                                cell.set(configuration: .smallChart)

                                cell.append(viewItem: activeAddressesViewItem) { [weak self] in
                                    self?.openProDataChart(proFeaturesActivated: viewItem.proFeaturesActivated, type: .activeAddresses)
                                }
                                cell.set(title: CoinProChartModule.ProChartType.activeAddresses.title)
                            }
                    )
            )
        }

        return rows
    }

    private func distributionSections(viewItem: CoinDetailsViewModel.ViewItem, isFirst: Bool) -> [SectionProtocol]? {
        let chartRows = distributionCharts(viewItem: viewItem)

        guard viewItem.hasMajorHolders || !chartRows.isEmpty else {
            return nil
        }

        return [
            Section(
                    id: "distribution-header",
                    footerState: .margin(height: .margin12),
                    rows: [
                        headerRow(title: "coin_page.token_distribution".localized, topSeparator: !isFirst)
                    ]
            ),
            Section(
                    id: "distribution",
                    footerState: .margin(height: .margin24),
                    rows: chartRows + [
                        Row<D1Cell>(
                                id: "major-holders",
                                height: .heightCell48,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                    cell.title = "coin_page.major_holders".localized
                                },
                                action: { [weak self] _ in
                                    self?.openMajorHolders()
                                }
                        )
                    ]
            )
        ]
    }

    private func tvlSections(viewItem: CoinDetailsViewModel.ViewItem) -> [SectionProtocol]? {
        guard let tvlChart = viewItem.tvlChart else {
            return nil
        }

        let tvlRow = Row<CoinDetailsMetricCell>(
                id: "tvl_chart",
                height: CoinDetailsMetricCell.cellHeight,
                bind: { [weak self] cell, _ in
                    cell.clear()
                    cell.set(configuration: .smallChart)

                    cell.append(viewItem: tvlChart) { [weak self] in
                        self?.openTvl()
                    }
                    cell.set(title: "coin_page.chart_tvl".localized)
                }
        )

        var sections: [SectionProtocol] = [
            Section(
                    id: "tvl-header",
                    footerState: .margin(height: .margin12),
                    rows: [
                        headerRow(title: "coin_page.token_tvl".localized),
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
            let tvlRankRow = Row<D2Cell>(
                    id: "market-cap-tvl-rank",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: !hasRatio)
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

        if let tvlRatio = viewItem.tvlRatio {
            let tvlRatioRow = Row<D7Cell>(
                    id: "market-cap-tvl-ratio",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: !hasRank, isLast: true)
                        cell.title = "coin_page.market_cap_tvl_ratio".localized
                        cell.value = tvlRatio
                    }
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

    private func investorDataSections(viewItem: CoinDetailsViewModel.ViewItem) -> [SectionProtocol]? {
        let treasuries = viewItem.treasuries
        let fundsInvested = viewItem.fundsInvested
        let reportsCount = viewItem.reportsCount

        var rows = [RowProtocol]()

        let hasTreasuries = treasuries != nil
        let hasFundsInvested = fundsInvested != nil
        let hasReports = reportsCount != nil

        if let treasuries = treasuries {
            let row = Row<D2Cell>(
                    id: "treasuries",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: !hasFundsInvested && !hasReports)
                        cell.title = "coin_page.treasuries".localized
                        cell.value = treasuries
                        cell.valueColor = .themeOz
                    },
                    action: { [weak self] _ in
                        self?.openTreasuries()
                    }
            )

            rows.append(row)
        }

        if let fundsInvested = fundsInvested {
            let row = Row<D2Cell>(
                    id: "funds-invested",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: !hasTreasuries, isLast: !hasReports)
                        cell.title = "coin_page.funds_invested".localized
                        cell.value = fundsInvested
                        cell.valueColor = .themeOz
                    },
                    action: { [weak self] _ in
                        self?.openFundsInvested()
                    }
            )

            rows.append(row)
        }

        if let reportsCount = reportsCount {
            let row = Row<D2Cell>(
                    id: "reports",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: !hasTreasuries && !hasFundsInvested, isLast: true)
                        cell.title = "coin_page.reports".localized
                        cell.value = reportsCount
                        cell.valueColor = .themeOz
                    },
                    action: { [weak self] _ in
                        self?.openReports()
                    }
            )

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
                            headerRow(title: "coin_page.investor_data".localized)
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
            let row = Row<D6Cell>(
                    id: "security-\(viewItem.type)",
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: index == 0, isLast: index == securityViewItems.count - 1 && !hasAudits)
                        cell.title = viewItem.type.title
                        cell.value = viewItem.value
                        cell.valueColor = viewItem.valueGrade.color
                        cell.valueImage = UIImage(named: "circle_information_20")
                    },
                    action: { [weak self] _ in
                        self?.openSecurityInfo(type: viewItem.type)
                    }
            )

            rows.append(row)
        }

        if !auditAddresses.isEmpty {
            let row = Row<D1Cell>(
                    id: "audits",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: !hasSecurity, isLast: true)
                        cell.title = "coin_page.audits".localized
                    },
                    action: { [weak self] _ in
                        self?.openAudits(addresses: auditAddresses)
                    }
            )

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
                            headerRow(title: "coin_page.security_parameters".localized)
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
            var isFirst = true
            if let proFeaturesSection = proFeaturesPassesSection(viewItem: viewItem) {
                sections.append(proFeaturesSection)
                isFirst = false
            }

            if let liquiditySections = liquiditySections(viewItem: viewItem, isFirst: isFirst) {
                sections.append(contentsOf: liquiditySections)
                isFirst = false
            }

            if let distributionSections = distributionSections(viewItem: viewItem, isFirst: isFirst) {
                sections.append(contentsOf: distributionSections)
                isFirst = false
            }

            if let tvlSections = tvlSections(viewItem: viewItem) {
                sections.append(contentsOf: tvlSections)
            }

            if let investorDataSections = investorDataSections(viewItem: viewItem) {
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

    var color: UIColor {
        switch self {
        case .low: return .themeLucian
        case .medium: return .themeIssykBlue
        case .high: return .themeRemus
        }
    }

}
