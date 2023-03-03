import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import SnapKit
import ComponentKit
import HUD
import MarketKit
import Chart

class CoinAnalyticsViewController: ThemeViewController {
    private let placeholderText = "•••"

    private let viewModel: CoinAnalyticsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    weak var parentNavigationController: UINavigationController?

    private var viewItem: CoinAnalyticsViewModel.ViewItem?

    init(viewModel: CoinAnalyticsViewModel) {
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
        tableView.showsVerticalScrollIndicator = false

        tableView.registerCell(forClass: PlaceholderCell.self)
        tableView.registerCell(forClass: MarketCardCell.self)
        tableView.registerCell(forClass: MarketWideCardCell.self)
        tableView.registerCell(forClass: CoinAnalyticsHoldersCell.self)
        tableView.sectionDataSource = self

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

    private func sync(viewItem: CoinAnalyticsViewModel.ViewItem?) {
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

    private func openTvl() {
        let viewController = CoinTvlModule.tvlViewController(coinUid: viewModel.coin.uid)
        parentNavigationController?.present(viewController, animated: true)
    }

    private func openTvlRank() {
        let viewController = MarketGlobalMetricModule.tvlInDefiViewController()
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openInvestors() {
        let viewController = CoinInvestorsModule.viewController(coinUid: viewModel.coin.uid)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openTreasuries() {
        let viewController = CoinTreasuriesModule.viewController(coin: viewModel.coin)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openReports() {
        let viewController = CoinReportsModule.viewController(coinUid: viewModel.coin.uid)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openAudits(addresses: [String]) {
        let viewController = CoinAuditsModule.viewController(addresses: addresses)
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func openProDataChart(type: CoinProChartModule.ProChartType) {
        let viewController = CoinProChartModule.viewController(coin: viewModel.coin, type: type)
        parentNavigationController?.present(viewController, animated: true)
    }

    private func placeholderChartData() -> ChartData {
        var chartItems = [ChartItem]()

        for i in 0..<8 {
            let baseTimeStamp = TimeInterval(i) * 100
            let baseValue = Decimal(i) * 2

            chartItems.append(contentsOf: [
                ChartItem(timestamp: baseTimeStamp).added(name: .rate, value: baseValue + 2),
                ChartItem(timestamp: baseTimeStamp + 25).added(name: .rate, value: baseValue + 6),
                ChartItem(timestamp: baseTimeStamp + 50).added(name: .rate, value: baseValue),
                ChartItem(timestamp: baseTimeStamp + 75).added(name: .rate, value: baseValue + 9)
            ])
        }

        chartItems.append(
                ChartItem(timestamp: 800).added(name: .rate, value: 16)
        )

        return ChartData(items: chartItems, startTimestamp: 0, endTimestamp: 800)
    }

}

extension CoinAnalyticsViewController: SectionsDataSource {

    private func chartRow(id: String, title: String, valueInfo: String, viewItem: Lockable<CoinAnalyticsViewModel.ChartViewItem>, infoAction: @escaping () -> (), action: @escaping () -> ()) -> RowProtocol {
        let value: String
        let chartData: ChartData

        switch viewItem {
        case .locked:
            value = placeholderText
            chartData = placeholderChartData()
        case .unlocked(let viewItem):
            value = viewItem.value
            chartData = viewItem.chartData
        }

        return Row<MarketWideCardCell>(
                id: id,
                height: MarketWideCardCell.height(),
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true)
                    cell.selectionStyle = viewItem.isLocked ? .none : .default

                    cell.bind(
                            title: title,
                            value: value,
                            valueInfo: viewItem.isLocked ? nil : valueInfo,
                            chartData: chartData,
                            chartColorType: viewItem.isLocked ? .neutral : .up,
                            onTapInfo: infoAction
                    )
                },
                action: viewItem.isLocked ? nil : { _ in action() }
        )
    }

    private func lockableRow(id: String, title: String, value: Lockable<String>? = nil, accessoryType: CellBuilderNew.CellElement.AccessoryType = .none, isFirst: Bool = false, isLast: Bool = false, action: Lockable<() -> ()>? = nil) -> RowProtocol {
        var rowValue: String?
        var rowAction: (() -> ())?

        if let value {
            switch value {
            case .locked: rowValue = placeholderText
            case .unlocked(let value): rowValue = value
            }
        }

        if let action {
            switch action {
            case .locked: ()
            case .unlocked(let action): rowAction = action
            }
        }

        return tableView.universalRow48(
                id: id,
                title: .subhead2(title),
                value: rowValue.map { .subhead1($0) },
                accessoryType: accessoryType,
                hash: rowValue,
                autoDeselect: true,
                isFirst: isFirst,
                isLast: isLast,
                action: rowAction
        )
    }

    private func lockInfoSection() -> SectionProtocol {
        let text = "coin_analytics.locked".localized

        return Section(
                id: "lock-info",
                headerState: .margin(height: .margin12),
                rows: [
                    Row<PlaceholderCell>(
                            id: "lock-info",
                            dynamicHeight: { _ in PlaceholderCell.height(text: text) },
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                cell.bind(
                                        icon: UIImage(named: "lock_48")?.withTintColor(.themeJacob),
                                        text: text
                                )
                            }
                    )
                ]
        )
    }

    private func cexVolumeSection(viewItem: Lockable<CoinAnalyticsViewModel.RankCardViewItem>) -> SectionProtocol {
        Section(
                id: "cex-volume",
                headerState: .margin(height: .margin12),
                rows: [
                    chartRow(
                            id: "cex-volume",
                            title: "coin_analytics.cex_volume".localized,
                            valueInfo: "coin_analytics.last_30d".localized,
                            viewItem: viewItem.lockableValue { $0.chart },
                            infoAction: { [weak self] in
                                self?.parentNavigationController?.present(InfoModule.tokenLiquidityInfo, animated: true)
                            },
                            action: { [weak self] in
                                self?.openProDataChart(type: .volume)
                            }
                    ),
                    lockableRow(
                            id: "cex-volume-rank",
                            title: "coin_analytics.30_day_rank".localized,
                            value: viewItem.lockableValue { $0.rank },
                            accessoryType: .disclosure,
                            isLast: true,
                            action: viewItem.lockableValue { _ in {
                                // todo
                            }}
                    )
                ]
        )
    }

    private func dexVolumeSection(viewItem: Lockable<CoinAnalyticsViewModel.RankCardViewItem>) -> SectionProtocol {
        Section(
                id: "dex-volume",
                headerState: .margin(height: .margin12),
                rows: [
                    chartRow(
                            id: "dex-volume",
                            title: "coin_analytics.dex_volume".localized,
                            valueInfo: "coin_analytics.last_30d".localized,
                            viewItem: viewItem.lockableValue { $0.chart },
                            infoAction: { [weak self] in
                                self?.parentNavigationController?.present(InfoModule.tokenLiquidityInfo, animated: true)
                            },
                            action: { [weak self] in
                                self?.openProDataChart(type: .volume)
                            }
                    ),
                    lockableRow(
                            id: "dex-volume-rank",
                            title: "coin_analytics.30_day_rank".localized,
                            value: viewItem.lockableValue { $0.rank },
                            accessoryType: .disclosure,
                            isLast: true,
                            action: viewItem.lockableValue { _ in {
                                // todo
                            }}
                    )
                ]
        )
    }

    private func dexLiquiditySection(viewItem: Lockable<CoinAnalyticsViewModel.RankCardViewItem>) -> SectionProtocol {
        Section(
                id: "dex-liquidity",
                headerState: .margin(height: .margin12),
                rows: [
                    chartRow(
                            id: "dex-liquidity",
                            title: "coin_analytics.dex_liquidity".localized,
                            valueInfo: "coin_analytics.current".localized,
                            viewItem: viewItem.lockableValue { $0.chart },
                            infoAction: { [weak self] in
                                self?.parentNavigationController?.present(InfoModule.tokenLiquidityInfo, animated: true)
                            },
                            action: { [weak self] in
                                self?.openProDataChart(type: .liquidity)
                            }
                    ),
                    lockableRow(
                            id: "dex-liquidity-rank",
                            title: "coin_analytics.rank".localized,
                            value: viewItem.lockableValue { $0.rank },
                            accessoryType: .disclosure,
                            isLast: true,
                            action: viewItem.lockableValue { _ in {
                                // todo
                            }}
                    )
                ]
        )
    }

    private func addressesSection(viewItem: Lockable<CoinAnalyticsViewModel.RankCardViewItem>) -> SectionProtocol {
        Section(
                id: "addresses",
                headerState: .margin(height: .margin12),
                rows: [
                    chartRow(
                            id: "addresses",
                            title: "coin_analytics.active_addresses".localized,
                            valueInfo: "coin_analytics.last_30d".localized,
                            viewItem: viewItem.lockableValue { $0.chart },
                            infoAction: { [weak self] in
                                self?.parentNavigationController?.present(InfoModule.tokenDistributionInfo, animated: true)
                            },
                            action: { [weak self] in
                                self?.openProDataChart(type: .activeAddresses)
                            }
                    ),
                    lockableRow(
                            id: "addresses-rank",
                            title: "coin_analytics.30_day_rank".localized,
                            value: viewItem.lockableValue { $0.rank },
                            accessoryType: .disclosure,
                            isLast: true,
                            action: viewItem.lockableValue { _ in {
                                // todo
                            }}
                    )
                ]
        )
    }

    private func txCountSection(viewItem: Lockable<CoinAnalyticsViewModel.TransactionCountViewItem>) -> SectionProtocol {
        Section(
                id: "tx-count",
                headerState: .margin(height: .margin12),
                rows: [
                    chartRow(
                            id: "tx-count",
                            title: "coin_analytics.transaction_count".localized,
                            valueInfo: "coin_analytics.last_30d".localized,
                            viewItem: viewItem.lockableValue { $0.chart },
                            infoAction: { [weak self] in
                                self?.parentNavigationController?.present(InfoModule.tokenDistributionInfo, animated: true)
                            },
                            action: { [weak self] in
                                self?.openProDataChart(type: .txCount)
                            }
                    ),
                    lockableRow(
                            id: "tx-volume",
                            title: "coin_analytics.30_day_volume".localized,
                            value: viewItem.lockableValue { $0.volume }
                    ),
                    lockableRow(
                            id: "tx-count-rank",
                            title: "coin_analytics.30_day_rank".localized,
                            value: viewItem.lockableValue { $0.rank },
                            accessoryType: .disclosure,
                            isLast: true,
                            action: viewItem.lockableValue { _ in {
                                // todo
                            }}
                    )
                ]
        )
    }

    private func holdersSection(viewItem: Lockable<CoinAnalyticsViewModel.HoldersViewItem>) -> SectionProtocol {
        struct Blockchain {
            let imageUrl: String?
            let name: String
            let value: String
            let action: (() -> ())?
        }

        let value: String
        let blockchains: [Blockchain]
        let chartItems: [(Decimal, UIColor?)]

        switch viewItem {
        case .locked:
            value = placeholderText
            blockchains = [
                Blockchain(imageUrl: nil, name: "Blockchain 1", value: placeholderText, action: nil),
                Blockchain(imageUrl: nil, name: "Blockchain 2", value: placeholderText, action: nil),
                Blockchain(imageUrl: nil, name: "Blockchain 3", value: placeholderText, action: nil),
            ]
            chartItems = [
                (50, UIColor.themeGray.withAlphaComponent(0.8)),
                (35, UIColor.themeGray.withAlphaComponent(0.6)),
                (15, UIColor.themeGray.withAlphaComponent(0.4))
            ]
        case .unlocked(let viewItem):
            value = viewItem.value
            blockchains = viewItem.holderViewItems.map { viewItem in
                Blockchain(
                        imageUrl: viewItem.imageUrl,
                        name: viewItem.name,
                        value: viewItem.value,
                        action: {
                            // todo
                        }
                )
            }
            chartItems = viewItem.holderViewItems.map { ($0.percent, $0.blockchainType.brandColor) }
        }

        return Section(
                id: "holders",
                headerState: .margin(height: .margin12),
                rows: [
                    Row<MarketWideCardCell>(
                            id: "holders",
                            height: MarketWideCardCell.height(hasChart: false, bottomMargin: .margin12),
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: true)
                                cell.selectionStyle = .none

                                cell.bind(
                                        title: "coin_analytics.holders".localized,
                                        value: value,
                                        valueInfo: viewItem.isLocked ? nil : "coin_analytics.current".localized,
                                        onTapInfo: {
                                            // todo
                                        }
                                )
                            }
                    ),
                    Row<CoinAnalyticsHoldersCell>(
                            id: "holders-pie",
                            height: CoinAnalyticsHoldersCell.height,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence)
                                cell.topSeparatorView.isHidden = true
                                cell.bind(items: chartItems)
                            }
                    )
                ] + blockchains.enumerated().map { index, blockchain in
                    tableView.universalRow56(
                            id: "holders-blockchain-\(index)",
                            image: .url(blockchain.imageUrl, placeholder: "placeholder_rectangle_32"),
                            title: .subhead2(blockchain.name),
                            value: .subhead1(blockchain.value),
                            accessoryType: .disclosure,
                            autoDeselect: true,
                            isLast: index == blockchains.count - 1,
                            action: blockchain.action
                    )
                }
        )
    }

    private func tvlSection(viewItem: Lockable<CoinAnalyticsViewModel.TvlViewItem>) -> SectionProtocol {
        Section(
                id: "tvl",
                headerState: .margin(height: .margin12),
                rows: [
                    chartRow(
                            id: "tvl",
                            title: "coin_analytics.project_tvl".localized,
                            valueInfo: "coin_analytics.current".localized,
                            viewItem: viewItem.lockableValue { $0.chart },
                            infoAction: { [weak self] in
                                self?.parentNavigationController?.present(InfoModule.tokenTvlInfo, animated: true)
                            },
                            action: { [weak self] in
                                self?.openTvl()
                            }
                    ),
                    lockableRow(
                            id: "tvl-rank",
                            title: "coin_analytics.rank".localized,
                            value: viewItem.lockableValue { $0.rank },
                            accessoryType: .disclosure,
                            action: viewItem.lockableValue { _ in { [weak self] in
                                self?.openTvlRank()
                            }}
                    ),
                    lockableRow(
                            id: "tvl-ratio",
                            title: "coin_analytics.tvl_ratio".localized,
                            value: viewItem.lockableValue { $0.ratio },
                            isLast: true
                    )
                ]
        )
    }

    private func revenueSection(viewItem: Lockable<CoinAnalyticsViewModel.RevenueViewItem>) -> SectionProtocol {
        let value: String

        switch viewItem {
        case .locked:
            value = placeholderText
        case .unlocked(let viewItem):
            value = viewItem.value
        }

        return Section(
                id: "revenue",
                headerState: .margin(height: .margin12),
                rows: [
                    Row<MarketWideCardCell>(
                            id: "revenue",
                            height: MarketWideCardCell.height(hasChart: false),
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: true)
                                cell.selectionStyle = .none

                                cell.bind(
                                        title: "coin_analytics.project_revenue".localized,
                                        value: value,
                                        valueInfo: viewItem.isLocked ? nil : "coin_analytics.last_30d".localized,
                                        onTapInfo: {
                                            // todo
                                        }
                                )
                            }
                    ),
                    lockableRow(
                            id: "revenue-rank",
                            title: "coin_analytics.30_day_rank".localized,
                            value: viewItem.lockableValue { $0.rank },
                            accessoryType: .disclosure,
                            isLast: true,
                            action: viewItem.lockableValue { _ in {
                                // todo
                            }}
                    )
                ]
        )
    }

    private func investorDataSection(investors: Lockable<String>?, treasuries: Lockable<String>?, reports: Lockable<String>?, auditAddresses: Lockable<[String]>?) -> SectionProtocol? {
        let items: [Any?] = [investors, treasuries, reports, auditAddresses]
        let rowCount = items.compactMap { $0 }.count

        guard rowCount > 0 else {
            return nil
        }

        var rows = [RowProtocol]()

        if let reports {
            rows.append(
                    lockableRow(
                            id: "reports",
                            title: "coin_analytics.reports".localized,
                            value: reports,
                            accessoryType: .disclosure,
                            isFirst: rows.isEmpty,
                            isLast: rows.count == rowCount - 1,
                            action: reports.lockableValue { _ in { [weak self] in
                                self?.openReports()
                            }}
                    )
            )
        }

        if let investors {
            rows.append(
                    lockableRow(
                            id: "investors",
                            title: "coin_analytics.funding".localized,
                            value: investors,
                            accessoryType: .disclosure,
                            isFirst: rows.isEmpty,
                            isLast: rows.count == rowCount - 1,
                            action: investors.lockableValue { _ in { [weak self] in
                                self?.openInvestors()
                            }}
                    )
            )
        }

        if let treasuries {
            rows.append(
                    lockableRow(
                            id: "treasuries",
                            title: "coin_analytics.treasuries".localized,
                            value: treasuries,
                            accessoryType: .disclosure,
                            isFirst: rows.isEmpty,
                            isLast: rows.count == rowCount - 1,
                            action: treasuries.lockableValue { _ in { [weak self] in
                                self?.openTreasuries()
                            }}
                    )
            )
        }

        if let auditAddresses {
            rows.append(
                    lockableRow(
                            id: "audits",
                            title: "coin_analytics.audits".localized,
                            accessoryType: .disclosure,
                            isFirst: rows.isEmpty,
                            isLast: rows.count == rowCount - 1,
                            action: auditAddresses.lockableValue { addresses in { [weak self] in
                                self?.openAudits(addresses: addresses)
                            }}
                    )
            )
        }

        return Section(
                id: "investor-data",
                headerState: .margin(height: .margin12),
                rows: [
                    tableView.headerInfoRow(id: "investor-data-header", title: "coin_analytics.other_data".localized) { [weak self] in
                        // todo
                    }
                ] + rows
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem {
            if viewItem.lockInfo {
                sections.append(lockInfoSection())
            }

            if let viewItem = viewItem.cexVolume {
                sections.append(cexVolumeSection(viewItem: viewItem))
            }

            if let viewItem = viewItem.dexVolume {
                sections.append(dexVolumeSection(viewItem: viewItem))
            }

            if let viewItem = viewItem.dexLiquidity {
                sections.append(dexLiquiditySection(viewItem: viewItem))
            }

            if let viewItem = viewItem.activeAddresses {
                sections.append(addressesSection(viewItem: viewItem))
            }

            if let viewItem = viewItem.transactionCount {
                sections.append(txCountSection(viewItem: viewItem))
            }

            if let viewItem = viewItem.holders {
                sections.append(holdersSection(viewItem: viewItem))
            }

            if let viewItem = viewItem.tvl {
                sections.append(tvlSection(viewItem: viewItem))
            }

            if let viewItem = viewItem.revenue {
                sections.append(revenueSection(viewItem: viewItem))
            }

            if let investorDataSection = investorDataSection(
                    investors: viewItem.investors,
                    treasuries: viewItem.treasuries,
                    reports: viewItem.reports,
                    auditAddresses: viewItem.auditAddresses
            ) {
                sections.append(investorDataSection)
            }

            sections.append(
                    Section(id: "footer", headerState: .margin(height: .margin32))
            )
        }

        return sections
    }

}
