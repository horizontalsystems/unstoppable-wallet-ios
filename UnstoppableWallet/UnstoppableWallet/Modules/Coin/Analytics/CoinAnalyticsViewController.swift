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
    private let emptyView = PlaceholderView()

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

        wrapperView.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        emptyView.image = UIImage(named: "not_available_48")?.withTintColor(.themeGray)
        emptyView.text = "coin_analytics.not_available".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false

        tableView.registerCell(forClass: PlaceholderCell.self)
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
        subscribe(disposeBag, viewModel.emptyViewDriver) { [weak self] visible in
            self?.emptyView.isHidden = !visible
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

        tableView.isHidden = viewItem == nil
        tableView.reload()
    }

    private func openSubscriptionInfo() {
        UrlManager.open(url: viewModel.analyticsLink, inAppController: parentNavigationController)
    }

    private func openActivateSubscription(address: String) {
        guard let viewController = ActivateSubscriptionModule.viewController(address: address) else {
            return
        }

        parentNavigationController?.present(viewController, animated: true)
    }

    private func openCexVolumeInfo() {
        let viewController = InfoModule.viewController(viewItems: [
            .header1(text: "coin_analytics.cex_volume".localized),
            .listItem(text: "coin_analytics.cex_volume.info1".localized),
            .listItem(text: "coin_analytics.cex_volume.info2".localized),
            .listItem(text: "coin_analytics.cex_volume.info3".localized),
            .listItem(text: "coin_analytics.cex_volume.info4".localized)
        ])

        parentNavigationController?.present(viewController, animated: true)
    }

    private func openDexVolumeInfo() {
        let viewController = InfoModule.viewController(viewItems: [
            .header1(text: "coin_analytics.dex_volume".localized),
            .listItem(text: "coin_analytics.dex_volume.info1".localized),
            .listItem(text: "coin_analytics.dex_volume.info2".localized),
            .listItem(text: "coin_analytics.dex_volume.info3".localized),
            .listItem(text: "coin_analytics.dex_volume.info4".localized),
            .text(text: "coin_analytics.dex_volume.tracked_dexes".localized),
            .listItem(text: "coin_analytics.dex_volume.tracked_dexes.info1".localized),
            .listItem(text: "coin_analytics.dex_volume.tracked_dexes.info2".localized)
        ])

        parentNavigationController?.present(viewController, animated: true)
    }

    private func openDexLiquidityInfo() {
        let viewController = InfoModule.viewController(viewItems: [
            .header1(text: "coin_analytics.dex_liquidity".localized),
            .listItem(text: "coin_analytics.dex_liquidity.info1".localized),
            .listItem(text: "coin_analytics.dex_liquidity.info2".localized),
            .listItem(text: "coin_analytics.dex_liquidity.info3".localized),
            .text(text: "coin_analytics.dex_liquidity.tracked_dexes".localized),
            .listItem(text: "coin_analytics.dex_liquidity.tracked_dexes.info1".localized),
            .listItem(text: "coin_analytics.dex_liquidity.tracked_dexes.info2".localized)
        ])

        parentNavigationController?.present(viewController, animated: true)
    }

    private func openAddressesInfo() {
        let viewController = InfoModule.viewController(viewItems: [
            .header1(text: "coin_analytics.active_addresses".localized),
            .listItem(text: "coin_analytics.active_addresses.info1".localized),
            .listItem(text: "coin_analytics.active_addresses.info2".localized),
            .listItem(text: "coin_analytics.active_addresses.info3".localized),
            .listItem(text: "coin_analytics.active_addresses.info4".localized),
            .listItem(text: "coin_analytics.active_addresses.info5".localized)
        ])

        parentNavigationController?.present(viewController, animated: true)
    }

    private func openTransactionCountInfo() {
        let viewController = InfoModule.viewController(viewItems: [
            .header1(text: "coin_analytics.transaction_count".localized),
            .listItem(text: "coin_analytics.transaction_count.info1".localized),
            .listItem(text: "coin_analytics.transaction_count.info2".localized),
            .listItem(text: "coin_analytics.transaction_count.info3".localized),
            .listItem(text: "coin_analytics.transaction_count.info4".localized),
            .listItem(text: "coin_analytics.transaction_count.info5".localized)
        ])

        parentNavigationController?.present(viewController, animated: true)
    }

    private func openHoldersInfo() {
        let viewController = InfoModule.viewController(viewItems: [
            .header1(text: "coin_analytics.holders".localized),
            .listItem(text: "coin_analytics.holders.info1".localized),
            .listItem(text: "coin_analytics.holders.info2".localized),
            .text(text: "coin_analytics.holders.tracked_blockchains".localized)
        ])

        parentNavigationController?.present(viewController, animated: true)
    }

    private func openTvlInfo() {
        let viewController = InfoModule.viewController(viewItems: [
            .header1(text: "coin_analytics.project_tvl.info_title".localized),
            .listItem(text: "coin_analytics.project_tvl.info1".localized),
            .listItem(text: "coin_analytics.project_tvl.info2".localized),
            .listItem(text: "coin_analytics.project_tvl.info3".localized),
            .listItem(text: "coin_analytics.project_tvl.info4".localized),
            .listItem(text: "coin_analytics.project_tvl.info5".localized)
        ])

        parentNavigationController?.present(viewController, animated: true)
    }

    private func openRevenueInfo() {
        let viewController = InfoModule.viewController(viewItems: [
            .header1(text: "coin_analytics.project_revenue".localized),
            .listItem(text: "coin_analytics.project_revenue.info1".localized),
            .listItem(text: "coin_analytics.project_revenue.info2".localized),
            .listItem(text: "coin_analytics.project_revenue.info3".localized)
        ])

        parentNavigationController?.present(viewController, animated: true)
    }

    private func openMajorHolders(blockchain: Blockchain) {
        let viewController = CoinMajorHoldersModule.viewController(coin: viewModel.coin, blockchain: blockchain)
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

    private func openRanks(type: CoinRankModule.RankType) {
        let viewController = CoinRankModule.viewController(type: type)
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

    private func chartRow(id: String, title: String, valueInfo: String, chartCurveType: ChartConfiguration.CurveType, viewItem: Previewable<CoinAnalyticsViewModel.ChartViewItem>, isLast: Bool, infoAction: @escaping () -> (), action: @escaping () -> ()) -> RowProtocol {
        let value: String?
        let chartData: ChartData
        let chartTrend: MovementTrend

        switch viewItem {
        case .preview:
            value = placeholderText
            chartData = placeholderChartData()
            chartTrend = .ignored
        case .regular(let viewItem):
            value = viewItem.value
            chartData = viewItem.chartData

            switch chartCurveType {
            case .line: chartTrend = viewItem.chartTrend
            case .bars: chartTrend = .neutral
            }
        }

        return Row<MarketWideCardCell>(
                id: id,
                height: MarketWideCardCell.height(),
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: isLast)
                    cell.selectionStyle = viewItem.isPreview ? .none : .default

                    cell.bind(
                            title: title,
                            value: value,
                            valueInfo: viewItem.isPreview ? nil : valueInfo,
                            chartData: chartData,
                            chartTrend: chartTrend,
                            chartCurveType: chartCurveType,
                            onTapInfo: infoAction
                    )
                },
                action: viewItem.isPreview ? nil : { _ in action() }
        )
    }

    private func previewableRow(id: String, title: String, value: Previewable<String>? = nil, accessoryType: CellBuilderNew.CellElement.AccessoryType = .none, isFirst: Bool = false, isLast: Bool = false, action: Previewable<() -> ()>? = nil) -> RowProtocol {
        var rowValue: String?
        var rowAction: (() -> ())?

        if let value {
            switch value {
            case .preview: rowValue = placeholderText
            case .regular(let value): rowValue = value
            }
        }

        if let action {
            switch action {
            case .preview: ()
            case .regular(let action): rowAction = action
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

    private func lockInfoSection(lockInfo: CoinAnalyticsViewModel.LockInfo) -> SectionProtocol {
        let icon: UIImage?
        let text: String
        let buttonTitle: String
        let buttonStyle: PrimaryButton.Style
        let onTapButton: () -> ()

        switch lockInfo {
        case .notSubscribed:
            icon = UIImage(named: "lock_48")?.withTintColor(.themeJacob)
            text = "coin_analytics.locked.not_subscribed".localized
            buttonTitle = "coin_analytics.locked.learn_more".localized
            buttonStyle = .gray
            onTapButton = { [weak self] in self?.openSubscriptionInfo() }
        case .notActivated(let address):
            icon = UIImage(named: "unlock_48")?.withTintColor(.themeJacob)
            text = "coin_analytics.locked.not_activated".localized
            buttonTitle = "coin_analytics.locked.activate".localized
            buttonStyle = .yellow
            onTapButton = { [weak self] in self?.openActivateSubscription(address: address) }
        }

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
                                        icon: icon,
                                        text: text,
                                        buttonTitle: buttonTitle,
                                        buttonStyle: buttonStyle,
                                        onTapButton: onTapButton
                                )
                            }
                    )
                ]
        )
    }

    private func cexVolumeSection(viewItem: CoinAnalyticsViewModel.RankCardViewItem) -> SectionProtocol {
        var rows: [RowProtocol] = [
            chartRow(
                    id: "cex-volume",
                    title: "coin_analytics.cex_volume".localized,
                    valueInfo: "coin_analytics.last_30d".localized,
                    chartCurveType: .bars,
                    viewItem: viewItem.chart,
                    isLast: viewItem.rank == nil,
                    infoAction: { [weak self] in
                        self?.openCexVolumeInfo()
                    },
                    action: { [weak self] in
                        self?.openProDataChart(type: .cexVolume)
                    }
            )
        ]

        if let rank = viewItem.rank {
            rows.append(
                    previewableRow(
                            id: "cex-volume-rank",
                            title: "coin_analytics.30_day_rank".localized,
                            value: rank,
                            accessoryType: .disclosure,
                            isLast: true,
                            action: rank.previewableValue { _ in { [weak self] in
                                self?.openRanks(type: .cexVolume)
                            }}
                    )
            )
        }

        return Section(
                id: "cex-volume",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func dexVolumeSection(viewItem: CoinAnalyticsViewModel.RankCardViewItem) -> SectionProtocol {
        var rows: [RowProtocol] = [
            chartRow(
                    id: "dex-volume",
                    title: "coin_analytics.dex_volume".localized,
                    valueInfo: "coin_analytics.last_30d".localized,
                    chartCurveType: .bars,
                    viewItem: viewItem.chart,
                    isLast: viewItem.rank == nil,
                    infoAction: { [weak self] in
                        self?.openDexVolumeInfo()
                    },
                    action: { [weak self] in
                        self?.openProDataChart(type: .dexVolume)
                    }
            )
        ]

        if let rank = viewItem.rank {
            rows.append(
                    previewableRow(
                            id: "dex-volume-rank",
                            title: "coin_analytics.30_day_rank".localized,
                            value: rank,
                            accessoryType: .disclosure,
                            isLast: true,
                            action: rank.previewableValue { _ in { [weak self] in
                                self?.openRanks(type: .dexVolume)
                            }}
                    )
            )
        }

        return Section(
                id: "dex-volume",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func dexLiquiditySection(viewItem: CoinAnalyticsViewModel.RankCardViewItem) -> SectionProtocol {
        var rows: [RowProtocol] = [
            chartRow(
                    id: "dex-liquidity",
                    title: "coin_analytics.dex_liquidity".localized,
                    valueInfo: "coin_analytics.current".localized,
                    chartCurveType: .line,
                    viewItem: viewItem.chart,
                    isLast: viewItem.rank == nil,
                    infoAction: { [weak self] in
                        self?.openDexLiquidityInfo()
                    },
                    action: { [weak self] in
                        self?.openProDataChart(type: .dexLiquidity)
                    }
            )
        ]

        if let rank = viewItem.rank {
            rows.append(
                    previewableRow(
                            id: "dex-liquidity-rank",
                            title: "coin_analytics.rank".localized,
                            value: rank,
                            accessoryType: .disclosure,
                            isLast: true,
                            action: rank.previewableValue { _ in { [weak self] in
                                self?.openRanks(type: .dexLiquidity)
                            }}
                    )
            )
        }

        return Section(
                id: "dex-liquidity",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func addressesSection(viewItem: CoinAnalyticsViewModel.ActiveAddressesViewItem) -> SectionProtocol {
        let items: [Any?] = [true, viewItem.count30d, viewItem.rank]
        let itemCount = items.compactMap { $0 }.count

        var rows: [RowProtocol] = [
            chartRow(
                    id: "addresses",
                    title: "coin_analytics.active_addresses".localized,
                    valueInfo: "coin_analytics.current".localized,
                    chartCurveType: .line,
                    viewItem: viewItem.chart,
                    isLast: itemCount == 1,
                    infoAction: { [weak self] in
                        self?.openAddressesInfo()
                    },
                    action: { [weak self] in
                        self?.openProDataChart(type: .activeAddresses)
                    }
            )
        ]

        if let count30d = viewItem.count30d {
            rows.append(
                    previewableRow(
                            id: "addresses-count-30d",
                            title: "coin_analytics.active_addresses.30_day_unique_addresses".localized,
                            value: count30d,
                            isLast: rows.count + 1 == itemCount
                    )
            )
        }

        if let rank = viewItem.rank {
            rows.append(
                    previewableRow(
                            id: "addresses-rank",
                            title: "coin_analytics.30_day_rank".localized,
                            value: rank,
                            accessoryType: .disclosure,
                            isLast: rows.count + 1 == itemCount,
                            action: rank.previewableValue { _ in { [weak self] in
                                self?.openRanks(type: .address)
                            }}
                    )
            )
        }

        return Section(
                id: "addresses",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func txCountSection(viewItem: CoinAnalyticsViewModel.TransactionCountViewItem) -> SectionProtocol {
        let items: [Any?] = [true, viewItem.volume, viewItem.rank]
        let itemCount = items.compactMap { $0 }.count

        var rows: [RowProtocol] = [
            chartRow(
                    id: "tx-count",
                    title: "coin_analytics.transaction_count".localized,
                    valueInfo: "coin_analytics.last_30d".localized,
                    chartCurveType: .bars,
                    viewItem: viewItem.chart,
                    isLast: itemCount == 1,
                    infoAction: { [weak self] in
                        self?.openTransactionCountInfo()
                    },
                    action: { [weak self] in
                        self?.openProDataChart(type: .txCount)
                    }
            )
        ]

        if let volume = viewItem.volume {
            rows.append(
                    previewableRow(
                            id: "tx-volume",
                            title: "coin_analytics.30_day_volume".localized,
                            value: volume,
                            isLast: rows.count + 1 == itemCount
                    )
            )
        }

        if let rank = viewItem.rank {
            rows.append(
                    previewableRow(
                            id: "tx-count-rank",
                            title: "coin_analytics.30_day_rank".localized,
                            value: rank,
                            accessoryType: .disclosure,
                            isLast: rows.count + 1 == itemCount,
                            action: rank.previewableValue { _ in { [weak self] in
                                self?.openRanks(type: .txCount)
                            }}
                    )
            )
        }

        return Section(
                id: "tx-count",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func holdersSection(viewItem: Previewable<CoinAnalyticsViewModel.HoldersViewItem>, rank: Previewable<String>?) -> SectionProtocol {
        struct Blockchain {
            let imageUrl: String?
            let name: String
            let value: String?
            let action: (() -> ())?
        }

        let value: String?
        let blockchains: [Blockchain]
        let chartItems: [(Decimal, UIColor?)]

        switch viewItem {
        case .preview:
            value = placeholderText
            blockchains = [
                Blockchain(imageUrl: nil, name: "Blockchain 1", value: placeholderText, action: nil),
                Blockchain(imageUrl: nil, name: "Blockchain 2", value: placeholderText, action: nil),
                Blockchain(imageUrl: nil, name: "Blockchain 3", value: placeholderText, action: nil),
            ]
            chartItems = [
                (0.5, UIColor.themeGray.withAlphaComponent(0.8)),
                (0.35, UIColor.themeGray.withAlphaComponent(0.6)),
                (0.15, UIColor.themeGray.withAlphaComponent(0.4))
            ]
        case .regular(let viewItem):
            value = viewItem.value
            blockchains = viewItem.holderViewItems.map { viewItem in
                Blockchain(
                        imageUrl: viewItem.imageUrl,
                        name: viewItem.name,
                        value: viewItem.value,
                        action: { [weak self] in
                            self?.openMajorHolders(blockchain: viewItem.blockchain)
                        }
                )
            }
            chartItems = viewItem.holderViewItems.map { ($0.percent, $0.blockchain.type.brandColor) }
        }

        var rows: [RowProtocol] = [
            Row<MarketWideCardCell>(
                    id: "holders",
                    height: MarketWideCardCell.height(hasChart: false, bottomMargin: .margin12),
                    bind: { [weak self] cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true)
                        cell.selectionStyle = .none

                        cell.bind(
                                title: "coin_analytics.holders".localized,
                                value: value,
                                valueInfo: viewItem.isPreview ? nil : "coin_analytics.current".localized,
                                onTapInfo: {
                                    self?.openHoldersInfo()
                                }
                        )
                    }
            ),
            Row<CoinAnalyticsHoldersCell>(
                    id: "holders-pie",
                    height: CoinAnalyticsHoldersCell.chartHeight + .margin16,
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
                    isLast: index == blockchains.count - 1 && rank == nil,
                    action: blockchain.action
            )
        }

        if let rank {
            rows.append(
                    previewableRow(
                            id: "holders-rank",
                            title: "coin_analytics.holders_rank".localized,
                            value: rank,
                            accessoryType: .disclosure,
                            isLast: true,
                            action: rank.previewableValue { _ in { [weak self] in
                                self?.openRanks(type: .holders)
                            }}
                    )
            )
        }

        return Section(
                id: "holders",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func tvlSection(viewItem: CoinAnalyticsViewModel.TvlViewItem) -> SectionProtocol {
        var rows: [RowProtocol] = [
            chartRow(
                    id: "tvl",
                    title: "coin_analytics.project_tvl".localized,
                    valueInfo: "coin_analytics.current".localized,
                    chartCurveType: .line,
                    viewItem: viewItem.chart,
                    isLast: viewItem.rank == nil && viewItem.ratio == nil,
                    infoAction: { [weak self] in
                        self?.openTvlInfo()
                    },
                    action: { [weak self] in
                        self?.openProDataChart(type: .tvl)
                    }
            )
        ]

        if let rank = viewItem.rank {
            rows.append(
                    previewableRow(
                            id: "tvl-rank",
                            title: "coin_analytics.rank".localized,
                            value: rank,
                            accessoryType: .disclosure,
                            isLast: viewItem.ratio == nil,
                            action: rank.previewableValue { _ in { [weak self] in
                                self?.openTvlRank()
                            }}
                    )
            )
        }

        if let ratio = viewItem.ratio {
            rows.append(
                    previewableRow(
                            id: "tvl-ratio",
                            title: "coin_analytics.tvl_ratio".localized,
                            value: ratio,
                            isLast: true
                    )
            )
        }

        return Section(
                id: "tvl",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func revenueSection(viewItem: CoinAnalyticsViewModel.RevenueViewItem) -> SectionProtocol {
        let value: String?
        let valueInfo: String?

        switch viewItem.value {
        case .preview:
            value = placeholderText
            valueInfo = nil
        case .regular(let _value):
            value = _value
            valueInfo = "coin_analytics.last_30d".localized
        }

        var rows: [RowProtocol] = [
            Row<MarketWideCardCell>(
                    id: "revenue",
                    height: MarketWideCardCell.height(hasChart: false),
                    bind: { [weak self] cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true)
                        cell.selectionStyle = .none

                        cell.bind(
                                title: "coin_analytics.project_revenue".localized,
                                value: value,
                                valueInfo: valueInfo,
                                onTapInfo: {
                                    self?.openRevenueInfo()
                                }
                        )
                    }
            )
        ]

        if let rank = viewItem.rank {
            rows.append(
                    previewableRow(
                            id: "revenue-rank",
                            title: "coin_analytics.30_day_rank".localized,
                            value: rank,
                            accessoryType: .disclosure,
                            isLast: true,
                            action: rank.previewableValue { _ in { [weak self] in
                                self?.openRanks(type: .revenue)
                            }}
                    )
            )
        }

        return Section(
                id: "revenue",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func otherDataSection(investors: Previewable<String>?, treasuries: Previewable<String>?, reports: Previewable<String>?, auditAddresses: Previewable<[String]>?) -> SectionProtocol? {
        let items: [Any?] = [investors, treasuries, reports, auditAddresses]
        let rowCount = items.compactMap { $0 }.count

        guard rowCount > 0 else {
            return nil
        }

        var rows = [RowProtocol]()

        if let reports {
            rows.append(
                    previewableRow(
                            id: "reports",
                            title: "coin_analytics.reports".localized,
                            value: reports,
                            accessoryType: .disclosure,
                            isFirst: rows.isEmpty,
                            isLast: rows.count == rowCount - 1,
                            action: reports.previewableValue { _ in { [weak self] in
                                self?.openReports()
                            }}
                    )
            )
        }

        if let investors {
            rows.append(
                    previewableRow(
                            id: "investors",
                            title: "coin_analytics.funding".localized,
                            value: investors,
                            accessoryType: .disclosure,
                            isFirst: rows.isEmpty,
                            isLast: rows.count == rowCount - 1,
                            action: investors.previewableValue { _ in { [weak self] in
                                self?.openInvestors()
                            }}
                    )
            )
        }

        if let treasuries {
            rows.append(
                    previewableRow(
                            id: "treasuries",
                            title: "coin_analytics.treasuries".localized,
                            value: treasuries,
                            accessoryType: .disclosure,
                            isFirst: rows.isEmpty,
                            isLast: rows.count == rowCount - 1,
                            action: treasuries.previewableValue { _ in { [weak self] in
                                self?.openTreasuries()
                            }}
                    )
            )
        }

        if let auditAddresses {
            rows.append(
                    previewableRow(
                            id: "audits",
                            title: "coin_analytics.audits".localized,
                            accessoryType: .disclosure,
                            isFirst: rows.isEmpty,
                            isLast: rows.count == rowCount - 1,
                            action: auditAddresses.previewableValue { addresses in { [weak self] in
                                self?.openAudits(addresses: addresses)
                            }}
                    )
            )
        }

        return Section(
                id: "investor-data",
                headerState: .margin(height: .margin12),
                rows: [
                    tableView.headerInfoRow(id: "investor-data-header", title: "coin_analytics.other_data".localized)
                ] + rows
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem {
            if let lockInfo = viewItem.lockInfo {
                sections.append(lockInfoSection(lockInfo: lockInfo))
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

            if let holdersViewItem = viewItem.holders {
                sections.append(holdersSection(viewItem: holdersViewItem, rank: viewItem.holdersRank))
            }

            if let viewItem = viewItem.tvl {
                sections.append(tvlSection(viewItem: viewItem))
            }

            if let viewItem = viewItem.revenue {
                sections.append(revenueSection(viewItem: viewItem))
            }

            if let otherDataSection = otherDataSection(
                    investors: viewItem.investors,
                    treasuries: viewItem.treasuries,
                    reports: viewItem.reports,
                    auditAddresses: viewItem.auditAddresses
            ) {
                sections.append(otherDataSection)
            }

            sections.append(
                    Section(id: "footer", headerState: .margin(height: .margin32))
            )
        }

        return sections
    }

}
