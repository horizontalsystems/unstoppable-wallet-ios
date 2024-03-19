import Chart
import Combine
import MarketKit
import RxCocoa
import RxRelay
import RxSwift
import UIKit

class CoinAnalyticsViewModel {
    private let queue = DispatchQueue(label: "\(AppConfig.label).coin_analytics_view_model", qos: .userInitiated)

    private let service: CoinAnalyticsService
    private let technicalIndicatorService: TechnicalIndicatorService
    private let coinIndicatorViewItemFactory: CoinIndicatorViewItemFactory
    private var cancellables = Set<AnyCancellable>()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)
    private let emptyViewRelay = BehaviorRelay<Bool>(value: false)

    private let indicatorViewItemsSubject = CurrentValueSubject<IndicatorViewItem, Never>(.empty)
    private let subscriptionInfoSubject = PassthroughSubject<Void, Never>()

    private var detailsShowed: Bool = false {
        didSet {
            sync()
        }
    }

    private let ratioFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private let holderShareFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.roundingMode = .halfEven
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    init(service: CoinAnalyticsService, technicalIndicatorService: TechnicalIndicatorService, coinIndicatorViewItemFactory: CoinIndicatorViewItemFactory) {
        self.service = service
        self.technicalIndicatorService = technicalIndicatorService
        self.coinIndicatorViewItemFactory = coinIndicatorViewItemFactory

        service.$state
            .receive(on: queue)
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        technicalIndicatorService.$state
            .receive(on: queue)
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        sync()
    }

    private func syncIndicators(enabled: Bool) {
        var loading = false
        var error = false
        var switchEnabled = false
        var viewItems = [CoinIndicatorViewItemFactory.ViewItem]()

        if enabled {
            switch technicalIndicatorService.state {
            case .loading: loading = true
            case .failed:
                error = true
                switchEnabled = true
            case let .completed(items):
                switchEnabled = true
                viewItems = coinIndicatorViewItemFactory.viewItems(items: items)
            }
        }

        let viewItem = IndicatorViewItem(loading: loading, error: error, switchEnabled: switchEnabled, viewItems: viewItems)
        indicatorViewItemsSubject.send(viewItem)
    }

    private func sync() {
        let state = service.state
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
            emptyViewRelay.accept(false)

            syncIndicators(enabled: false)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
            emptyViewRelay.accept(false)

            syncIndicators(enabled: false)
        case let .preview(analyticsPreview):
            let viewItem = previewViewItem(analyticsPreview: analyticsPreview)

            if viewItem.isEmpty {
                viewItemRelay.accept(nil)
                emptyViewRelay.accept(true)
            } else {
                viewItemRelay.accept(viewItem)
                emptyViewRelay.accept(false)
            }

            loadingRelay.accept(false)
            syncErrorRelay.accept(false)

            syncIndicators(enabled: false)
            subscriptionInfoSubject.send()
        case let .success(analytics):
            let viewItem = viewItem(analytics: analytics)

            if viewItem.isEmpty {
                viewItemRelay.accept(nil)
                emptyViewRelay.accept(true)
            } else {
                viewItemRelay.accept(viewItem)
                emptyViewRelay.accept(false)
            }

            loadingRelay.accept(false)
            syncErrorRelay.accept(false)

            syncIndicators(enabled: true)
        }
    }

    private func rankString(value: Int) -> String {
        "#\(value)"
    }

    private func chartViewItem(points: [ChartPoint], value: Decimal? = nil, postfix: ChartPreviewValuePostfix) -> ChartViewItem? {
        guard let first = points.first, let last = points.last else {
            return nil
        }

        let chartItems = points.map {
            ChartItem(timestamp: $0.timestamp).added(name: ChartData.rate, value: $0.value)
        }

        let chartData = ChartData(items: chartItems, startWindow: first.timestamp, endWindow: last.timestamp)

        var valueString: String?

        if let value {
            switch postfix {
            case .currency: valueString = ValueFormatter.instance.formatShort(currency: service.currency, value: value)
            case .coin: valueString = ValueFormatter.instance.formatShort(value: value).map { [$0, coin.code].joined(separator: " ") }
            case .noPostfix: valueString = ValueFormatter.instance.formatShort(value: value)
            }
        }

        return ChartViewItem(
            value: valueString ?? "n/a".localized,
            chartData: chartData,
            chartTrend: first.value < last.value ? .up : .down
        )
    }

    private func viewItem(technicalAdvice: TechnicalAdvice?) -> TechnicalAdviceViewItem? {
        guard let technicalAdvice, let advice = technicalAdvice.advice else {
            return nil
        }

        return TechnicalAdviceViewItem(
            title: advice.title,
            sliderIndex: advice.sliderIndex,
            details: coinIndicatorViewItemFactory.advice(technicalAdvice: technicalAdvice),
            detailsShowed: detailsShowed
        )
    }

    private func rankCardViewItem(points: [ChartPoint]?, value: Decimal?, postfix: ChartPreviewValuePostfix, rank: Int?, rating: String?) -> RankCardViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, value: value, postfix: postfix) else {
            return nil
        }

        return RankCardViewItem(
            chart: .regular(value: chartViewItem),
            rank: rank.map { .regular(value: rankString(value: $0)) },
            rating: rating.flatMap { CoinAnalyticsModule.Rating(rawValue: $0) }.map { .regular(value: $0) }
        )
    }

    private func activeAddressesViewItem(points: [ChartPoint]?, value: Decimal?, count30d: Int?, rank: Int?, rating: String?) -> ActiveAddressesViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, value: value, postfix: .noPostfix) else {
            return nil
        }

        return ActiveAddressesViewItem(
            chart: .regular(value: chartViewItem),
            count30d: count30d.flatMap { ValueFormatter.instance.formatShort(value: Decimal($0)) }.map { .regular(value: $0) },
            rank: rank.map { .regular(value: rankString(value: $0)) },
            rating: rating.flatMap { CoinAnalyticsModule.Rating(rawValue: $0) }.map { .regular(value: $0) }
        )
    }

    private func transactionCountViewItem(points: [ChartPoint]?, value: Decimal?, volume: Decimal?, rank: Int?, rating: String?) -> TransactionCountViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, value: value, postfix: .noPostfix) else {
            return nil
        }

        return TransactionCountViewItem(
            chart: .regular(value: chartViewItem),
            volume: volume.flatMap { ValueFormatter.instance.formatShort(value: $0) }.map { .regular(value: [$0, coin.code].joined(separator: " ")) },
            rank: rank.map { .regular(value: rankString(value: $0)) },
            rating: rating.flatMap { CoinAnalyticsModule.Rating(rawValue: $0) }.map { .regular(value: $0) }
        )
    }

    private func holdersViewItem(holderBlockchains: [Analytics.HolderBlockchain]?) -> Previewable<HoldersViewItem>? {
        struct Item {
            let blockchain: Blockchain
            let count: Decimal
        }

        guard let holderBlockchains else {
            return nil
        }

        let blockchains = service.blockchains(uids: holderBlockchains.filter { $0.holdersCount > 0 }.map(\.uid))

        let items = holderBlockchains.sorted { $0.holdersCount > $1.holdersCount }.compactMap { holderBlockchain -> Item? in
            guard let blockchain = blockchains.first(where: { $0.uid == holderBlockchain.uid }) else {
                return nil
            }

            return Item(blockchain: blockchain, count: holderBlockchain.holdersCount)
        }

        guard !items.isEmpty else {
            return nil
        }

        let total = items.map(\.count).reduce(0, +)

        let viewItem = HoldersViewItem(
            value: ValueFormatter.instance.formatShort(value: total),
            holderViewItems: items.map { item in
                let percent = item.count / total

                return HolderViewItem(
                    blockchain: item.blockchain,
                    imageUrl: item.blockchain.type.imageUrl,
                    name: item.blockchain.name,
                    value: holderShareFormatter.string(from: percent as NSNumber),
                    percent: percent
                )
            }
        )

        return .regular(value: viewItem)
    }

    private func tvlViewItem(points: [ChartPoint]?, rank: Int?, ratio: Decimal?, rating: String?) -> TvlViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, value: points.last?.value, postfix: .currency) else {
            return nil
        }

        return TvlViewItem(
            chart: .regular(value: chartViewItem),
            rank: rank.map { .regular(value: rankString(value: $0)) },
            ratio: ratio.flatMap { ratioFormatter.string(from: $0 as NSNumber) }.map { .regular(value: $0) },
            rating: rating.flatMap { CoinAnalyticsModule.Rating(rawValue: $0) }.map { .regular(value: $0) }
        )
    }

    private func valueRankViewItem(value: Decimal?, rank: Int?, description: String?) -> ValueRankViewItem? {
        guard let value, let formattedValue = ValueFormatter.instance.formatShort(currency: service.currency, value: value) else {
            return nil
        }

        return ValueRankViewItem(
            value: .regular(value: formattedValue),
            rank: rank.map { .regular(value: rankString(value: $0)) },
            description: description
        )
    }

    private func issueBlockchainViewItems(issueBlockchains: [Analytics.IssueBlockchain]) -> [IssueBlockchainViewItem]? {
        let blockchains = service.blockchains(uids: issueBlockchains.map(\.blockchain))

        let viewItems: [IssueBlockchainViewItem] = issueBlockchains.compactMap { issueBlockchain in
            guard let blockchain = blockchains.first(where: { $0.uid == issueBlockchain.blockchain }) else {
                return nil
            }

            return IssueBlockchainViewItem(
                blockchain: blockchain,
                allItems: issueBlockchain.issues.map { issue in
                    IssueViewItem(
                        title: issue.title ?? issue.description ?? "",
                        description: issue.title != nil ? issue.description : nil,
                        level: .init(impact: issue.issues?.first?.impact),
                        type: issue.issue,
                        issues: issue.issues.map { $0.compactMap(\.description) } ?? []
                    )
                }.sorted { $0.level.rawValue < $1.level.rawValue }
            )
        }

        guard !viewItems.isEmpty else {
            return nil
        }

        return viewItems.sorted { $0.blockchain.type.order < $1.blockchain.type.order }
    }

    private func viewItem(analytics: Analytics) -> ViewItem {
        ViewItem(
            cexVolume: rankCardViewItem(
                points: analytics.cexVolume?.aggregatedChartPoints.points,
                value: analytics.cexVolume?.aggregatedChartPoints.aggregatedValue,
                postfix: .currency,
                rank: analytics.cexVolume?.rank30d,
                rating: analytics.cexVolume?.rating
            ),
            dexVolume: rankCardViewItem(
                points: analytics.dexVolume?.aggregatedChartPoints.points,
                value: analytics.dexVolume?.aggregatedChartPoints.aggregatedValue,
                postfix: .currency,
                rank: analytics.dexVolume?.rank30d,
                rating: analytics.dexVolume?.rating
            ),
            dexLiquidity: rankCardViewItem(
                points: analytics.dexLiquidity?.chartPoints,
                value: analytics.dexLiquidity?.chartPoints.last?.value,
                postfix: .currency,
                rank: analytics.dexLiquidity?.rank,
                rating: analytics.dexLiquidity?.rating
            ),
            activeAddresses: activeAddressesViewItem(
                points: analytics.addresses?.chartPoints,
                value: analytics.addresses?.chartPoints.last?.value,
                count30d: analytics.addresses?.count30d,
                rank: analytics.addresses?.rank30d,
                rating: analytics.addresses?.rating
            ),
            transactionCount: transactionCountViewItem(
                points: analytics.transactions?.aggregatedChartPoints.points,
                value: analytics.transactions?.aggregatedChartPoints.aggregatedValue,
                volume: analytics.transactions?.volume30d,
                rank: analytics.transactions?.rank30d,
                rating: analytics.transactions?.rating
            ),
            holders: holdersViewItem(holderBlockchains: analytics.holders),
            holdersRank: analytics.holdersRank.map { .regular(value: rankString(value: $0)) },
            holdersRating: analytics.holdersRating.flatMap { CoinAnalyticsModule.Rating(rawValue: $0) }.map { .regular(value: $0) },
            tvl: tvlViewItem(
                points: analytics.tvl?.chartPoints,
                rank: analytics.tvl?.rank,
                ratio: analytics.tvl?.ratio,
                rating: analytics.tvl?.rating
            ),
            fee: valueRankViewItem(
                value: analytics.fee?.value30d,
                rank: analytics.fee?.rank30d,
                description: analytics.fee?.description
            ),
            revenue: valueRankViewItem(
                value: analytics.revenue?.value30d,
                rank: analytics.revenue?.rank30d,
                description: analytics.revenue?.description
            ),
            reports: analytics.reports
                .map { .regular(value: "\($0)") },
            investors: analytics.fundsInvested
                .flatMap { ValueFormatter.instance.formatShort(currency: service.currency, value: $0) }
                .map { .regular(value: $0) },
            treasuries: analytics.treasuries
                .flatMap { ValueFormatter.instance.formatShort(currency: service.currency, value: $0) }
                .map { .regular(value: $0) },
            auditAddresses: service.auditAddresses
                .map { .regular(value: $0) },
            issueBlockchains: analytics.issueBlockchains.flatMap { issueBlockchainViewItems(issueBlockchains: $0) },
            technicalAdvice: viewItem(technicalAdvice: analytics.technicalAdvice)
        )
    }

    private func previewViewItem(analyticsPreview data: AnalyticsPreview) -> ViewItem {
        ViewItem(
            cexVolume: data.cexVolume ? RankCardViewItem(chart: .preview, rank: data.cexVolumeRank30d ? .preview : nil, rating: data.cexVolumeRating ? .preview : nil) : nil,
            dexVolume: data.dexVolume ? RankCardViewItem(chart: .preview, rank: data.dexVolumeRank30d ? .preview : nil, rating: data.dexVolumeRating ? .preview : nil) : nil,
            dexLiquidity: data.dexLiquidity ? RankCardViewItem(chart: .preview, rank: data.dexLiquidityRank ? .preview : nil, rating: data.dexLiquidityRating ? .preview : nil) : nil,
            activeAddresses: data.addresses ? ActiveAddressesViewItem(chart: .preview, count30d: data.addressesCount30d ? .preview : nil, rank: data.addressesRank30d ? .preview : nil, rating: data.addressesRating ? .preview : nil) : nil,
            transactionCount: data.transactions ? TransactionCountViewItem(chart: .preview, volume: data.transactionsVolume30d ? .preview : nil, rank: data.transactionsRank30d ? .preview : nil, rating: data.transactionsRating ? .preview : nil) : nil,
            holders: data.holders ? .preview : nil,
            holdersRank: data.holdersRank ? .preview : nil,
            holdersRating: data.holdersRating ? .preview : nil,
            tvl: data.tvl ? TvlViewItem(chart: .preview, rank: data.tvlRank ? .preview : nil, ratio: data.tvlRatio ? .preview : nil, rating: data.tvlRating ? .preview : nil) : nil,
            fee: data.fee ? ValueRankViewItem(value: .preview, rank: data.feeRank30d ? .preview : nil, description: nil) : nil,
            revenue: data.revenue ? ValueRankViewItem(value: .preview, rank: data.revenueRank30d ? .preview : nil, description: nil) : nil,
            reports: data.reports ? .preview : nil,
            investors: data.fundsInvested ? .preview : nil,
            treasuries: data.treasuries ? .preview : nil,
            auditAddresses: service.auditAddresses != nil ? .preview : nil,
            issueBlockchains: nil,
            technicalAdvice: nil
        )
    }
}

extension CoinAnalyticsViewModel {
    var period: String {
        technicalIndicatorService.period.title
    }

    var periodViewItems: [SelectorModule.ViewItem] {
        technicalIndicatorService.allPeriods.map {
            .init(title: $0.title, selected: $0 == technicalIndicatorService.period)
        }
    }

    var detailAdviceSectionViewItems: [CoinIndicatorViewItemFactory.SectionDetailViewItem]? {
        guard let items = technicalIndicatorService.state.data else {
            return nil
        }
        return coinIndicatorViewItemFactory.detailViewItems(items: items)
    }

    func onSelectPeriod(index: Int) {
        guard let period = technicalIndicatorService.allPeriods.at(index: index) else {
            return
        }

        technicalIndicatorService.period = period
    }
}

extension CoinAnalyticsViewModel {
    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    var emptyViewDriver: Driver<Bool> {
        emptyViewRelay.asDriver()
    }

    var indicatorViewItemsPublisher: AnyPublisher<IndicatorViewItem, Never> {
        indicatorViewItemsSubject.eraseToAnyPublisher()
    }

    var subscriptionInfoPublisher: AnyPublisher<Void, Never> {
        subscriptionInfoSubject.eraseToAnyPublisher()
    }

    var coin: Coin {
        service.coin
    }

    func onLoad() {
        service.sync()
    }

    func onTapRetry() {
        service.sync()
    }

    func onTapDetails() {
        detailsShowed.toggle()
    }
}

extension CoinAnalyticsViewModel {
    struct ViewItem {
        let cexVolume: RankCardViewItem?
        let dexVolume: RankCardViewItem?
        let dexLiquidity: RankCardViewItem?
        let activeAddresses: ActiveAddressesViewItem?
        let transactionCount: TransactionCountViewItem?
        let holders: Previewable<HoldersViewItem>?
        let holdersRank: Previewable<String>?
        let holdersRating: Previewable<CoinAnalyticsModule.Rating>?
        let tvl: TvlViewItem?
        let fee: ValueRankViewItem?
        let revenue: ValueRankViewItem?
        let reports: Previewable<String>?
        let investors: Previewable<String>?
        let treasuries: Previewable<String>?
        let auditAddresses: Previewable<[String]>?
        let issueBlockchains: [IssueBlockchainViewItem]?
        let technicalAdvice: TechnicalAdviceViewItem?

        var isEmpty: Bool {
            let items: [Any?] = [cexVolume, dexVolume, dexLiquidity, activeAddresses, transactionCount, holders, tvl, revenue, reports, investors, treasuries, technicalAdvice]
            return items.compactMap { $0 }.isEmpty
        }
    }

    struct IndicatorViewItem {
        static let empty = IndicatorViewItem(loading: false, error: false, switchEnabled: false, viewItems: [])

        let loading: Bool
        let error: Bool
        let switchEnabled: Bool
        let viewItems: [CoinIndicatorViewItemFactory.ViewItem]
    }

    struct ChartViewItem {
        let value: String
        let chartData: ChartData
        let chartTrend: MovementTrend
    }

    struct TechnicalAdviceViewItem {
        let title: String
        let sliderIndex: Int
        let details: String
        let detailsShowed: Bool
    }

    struct RankCardViewItem {
        let chart: Previewable<ChartViewItem>
        let rank: Previewable<String>?
        let rating: Previewable<CoinAnalyticsModule.Rating>?
    }

    struct ActiveAddressesViewItem {
        let chart: Previewable<ChartViewItem>
        let count30d: Previewable<String>?
        let rank: Previewable<String>?
        let rating: Previewable<CoinAnalyticsModule.Rating>?
    }

    struct TransactionCountViewItem {
        let chart: Previewable<ChartViewItem>
        let volume: Previewable<String>?
        let rank: Previewable<String>?
        let rating: Previewable<CoinAnalyticsModule.Rating>?
    }

    struct HoldersViewItem {
        let value: String?
        let holderViewItems: [HolderViewItem]
    }

    struct HolderViewItem {
        let blockchain: Blockchain
        let imageUrl: String
        let name: String
        let value: String?
        let percent: Decimal
    }

    struct IssueBlockchainViewItem {
        let blockchain: Blockchain
        let allItems: [IssueViewItem]

        var highRiskCount: Int {
            allItems.filter { $0.level == .highRisk }.count
        }

        var mediumRiskCount: Int {
            allItems.filter { $0.level == .mediumRisk }.count
        }

        var lowRiskCount: Int {
            allItems.filter { $0.level == .attentionRequired || $0.level == .informational }.count
        }

        var coreItems: [IssueViewItem] {
            allItems.filter { $0.type == "core" }
        }

        var generalItems: [IssueViewItem] {
            allItems.filter { $0.type == "general" }
        }
    }

    struct IssueViewItem {
        let title: String
        let description: String?
        let level: Level
        let type: String?
        let issues: [String]

        enum Level: Int {
            case highRisk
            case mediumRisk
            case attentionRequired
            case informational
            case regular

            init(impact: String?) {
                switch impact {
                case "Critical", "High": self = .highRisk
                case "Medium": self = .mediumRisk
                case "Low": self = .attentionRequired
                case "Informational": self = .informational
                default: self = .regular
                }
            }
        }
    }

    struct TvlViewItem {
        let chart: Previewable<ChartViewItem>
        let rank: Previewable<String>?
        let ratio: Previewable<String>?
        let rating: Previewable<CoinAnalyticsModule.Rating>?
    }

    struct ValueRankViewItem {
        let value: Previewable<String>
        let rank: Previewable<String>?
        let description: String?
    }

    enum ChartPreviewValuePostfix {
        case currency
        case coin
        case noPostfix
    }
}

enum Previewable<T> {
    case preview
    case regular(value: T)

    var isPreview: Bool {
        switch self {
        case .preview: return true
        case .regular: return false
        }
    }

    func previewableValue<P>(mapper: (T) -> P) -> Previewable<P> {
        switch self {
        case .preview: return .preview
        case let .regular(value): return .regular(value: mapper(value))
        }
    }

    func value<P>(mapper: (T) -> P) -> P? {
        switch self {
        case .preview: return nil
        case let .regular(value): return mapper(value)
        }
    }
}

extension HsPointTimePeriod {
    var title: String {
        switch self {
        case .minute30, .hour8: return "" // not used
        case .hour1: return "coin_analytics.period.1h".localized
        case .hour4: return "coin_analytics.period.4h".localized
        case .day1: return "coin_analytics.period.1d".localized
        case .week1: return "coin_analytics.period.1w".localized
        case .month1: return "coin_analytics.period.1m".localized
        }
    }
}
