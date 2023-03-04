import UIKit
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import Chart

class CoinAnalyticsViewModel {
    private let service: CoinAnalyticsService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

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

    init(service: CoinAnalyticsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: CoinAnalyticsService.State) {
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        case .locked(let lockedAnalytics):
            viewItemRelay.accept(lockedViewItem(lockedAnalytics: lockedAnalytics))
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .success(let analytics):
            viewItemRelay.accept(viewItem(analytics: analytics))
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        }
    }

    private func rankString(value: Int) -> String {
        "#\(value)"
    }

    private func chartViewItem(points: [ChartPoint], customValue: Decimal? = nil, type: CoinProChartModule.ChartValueType, postfix: ChartPreviewValuePostfix) -> ChartViewItem? {
        guard let first = points.first, let last = points.last else {
            return nil
        }

        let chartItems = points.map {
            ChartItem(timestamp: $0.timestamp).added(name: .rate, value: $0.value)
        }

        let chartData = ChartData(items: chartItems, startTimestamp: first.timestamp, endTimestamp: last.timestamp)

        var value: Decimal?

        if let customValue {
            value = customValue
        } else {
            switch type {
            case .last: value = last.value
            case .cumulative: value = points.map { $0.value }.reduce(0, +)
            }
        }

        var valueString: String?

        if let value {
            switch postfix {
            case .currency: valueString = ValueFormatter.instance.formatShort(currency: service.currency, value: value)
            case .coin: valueString = ValueFormatter.instance.formatShort(value: value).map { [$0, coin.code].joined(separator: " ") }
            case .noPostfix: valueString = ValueFormatter.instance.formatShort(value: value)
            }
        }

        return ChartViewItem(value: valueString ?? "n/a".localized, chartData: chartData)
    }

    private func rankCardViewItem(points: [ChartPoint]?, value: Int? = nil, type: CoinProChartModule.ChartValueType, postfix: ChartPreviewValuePostfix, rank: Int?) -> RankCardViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, customValue: value.map { Decimal($0) }, type: type, postfix: postfix) else {
            return nil
        }

        return RankCardViewItem(
                chart: .unlocked(value: chartViewItem),
                rank: rank.map { .unlocked(value: rankString(value: $0)) }
        )
    }

    private func transactionCountViewItem(points: [ChartPoint]?, volume: Decimal?, rank: Int?) -> TransactionCountViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, type: .cumulative, postfix: .noPostfix) else {
            return nil
        }

        return TransactionCountViewItem(
                chart: .unlocked(value: chartViewItem),
                volume: volume.flatMap { ValueFormatter.instance.formatShort(value: $0) }.map { .unlocked(value: [$0, coin.code].joined(separator: " ")) },
                rank: rank.map { .unlocked(value: rankString(value: $0)) }
        )
    }

    private func holdersViewItem(holderBlockchains: [AnalyticsResponse.HolderBlockchain]?) -> Lockable<HoldersViewItem>? {
        struct Item {
            let blockchain: Blockchain
            let count: Int
        }

        guard let holderBlockchains else {
            return nil
        }

        let blockchains = service.blockchains(uids: holderBlockchains.filter { $0.count > 0 }.map { $0.uid })

        let items = holderBlockchains.compactMap { holderBlockchain -> Item? in
            guard let blockchain = blockchains.first(where: { $0.uid == holderBlockchain.uid }) else {
                return nil
            }

            return Item(blockchain: blockchain, count: holderBlockchain.count)
        }

        guard !items.isEmpty else {
            return nil
        }

        let total = items.map { Decimal($0.count) }.reduce(0, +)

        let viewItem = HoldersViewItem(
                value: ValueFormatter.instance.formatShort(value: total),
                holderViewItems: items.map { item in
                    let percent = Decimal(item.count) / total

                    return HolderViewItem(
                            blockchainType: item.blockchain.type,
                            imageUrl: item.blockchain.type.imageUrl,
                            name: item.blockchain.name,
                            value: holderShareFormatter.string(from: percent as NSNumber),
                            percent: percent
                    )
                }
        )

        return .unlocked(value: viewItem)
    }

    private func tvlViewItem(points: [ChartPoint]?, rank: Int?, ratio: Decimal?) -> TvlViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, type: .last, postfix: .currency) else {
            return nil
        }

        return TvlViewItem(
                chart: .unlocked(value: chartViewItem),
                rank: rank.map { .unlocked(value: rankString(value: $0)) },
                ratio: ratio.flatMap { ratioFormatter.string(from: $0 as NSNumber) }.map { .unlocked(value: $0) }
        )
    }

    private func revenueViewItem(value: Decimal?, rank: Int?) -> RevenueViewItem? {
        guard let value, let formattedValue = ValueFormatter.instance.formatShort(currency: service.currency, value: value) else {
            return nil
        }

        return RevenueViewItem(
                value: .unlocked(value: formattedValue),
                rank: rank.map { .unlocked(value: rankString(value: $0)) }
        )
    }

    private func viewItem(analytics: AnalyticsResponse) -> ViewItem {
        ViewItem(
                lockInfo: false,
                cexVolume: rankCardViewItem(
                        points: analytics.cexVolume?.chartPoints,
                        type: .cumulative,
                        postfix: .currency,
                        rank: analytics.cexVolume?.ranks?.month
                ),
                dexVolume: rankCardViewItem(
                        points: analytics.dexVolume?.chartPoints,
                        type: .cumulative,
                        postfix: .currency,
                        rank: analytics.dexVolume?.ranks?.month
                ),
                dexLiquidity: rankCardViewItem(
                        points: analytics.dexLiquidity?.chartPoints,
                        type: .last,
                        postfix: .currency,
                        rank: analytics.dexLiquidity?.rank
                ),
                activeAddresses: rankCardViewItem(
                        points: analytics.addresses?.chartPoints,
                        value: analytics.addresses?.counts?.month,
                        type: .cumulative,
                        postfix: .noPostfix,
                        rank: analytics.addresses?.ranks?.month
                ),
                transactionCount: transactionCountViewItem(
                        points: analytics.transactions?.chartPoints,
                        volume: analytics.transactions?.volumes?.month,
                        rank: analytics.transactions?.ranks?.month
                ),
                holders: holdersViewItem(holderBlockchains: analytics.holders),
                tvl: tvlViewItem(
                        points: analytics.tvl?.chartPoints,
                        rank: analytics.tvl?.rank,
                        ratio: analytics.tvl?.ratio
                ),
                revenue: revenueViewItem(
                        value: analytics.revenue?.values?.month,
                        rank: analytics.revenue?.ranks?.month
                ),
                reports: analytics.reports
                        .map { .unlocked(value: "\($0)") },
                investors: analytics.fundsInvested
                        .flatMap { ValueFormatter.instance.formatShort(currency: service.currency, value: $0) }
                        .map { .unlocked(value: $0) },
                treasuries: analytics.treasuries
                        .flatMap { ValueFormatter.instance.formatShort(currency: service.currency, value: $0) }
                        .map { .unlocked(value: $0) },
                auditAddresses: service.auditAddresses
                        .map { .unlocked(value: $0) }
        )
    }

    private func lockedViewItem(lockedAnalytics: LockedAnalyticsResponse) -> ViewItem {
        ViewItem(
                lockInfo: true,
                cexVolume: lockedAnalytics.cexVolume ? RankCardViewItem(chart: .locked, rank: .locked) : nil,
                dexVolume: lockedAnalytics.dexVolume ? RankCardViewItem(chart: .locked, rank: .locked) : nil,
                dexLiquidity: lockedAnalytics.dexLiquidity ? RankCardViewItem(chart: .locked, rank: .locked) : nil,
                activeAddresses: lockedAnalytics.addresses ? RankCardViewItem(chart: .locked, rank: .locked) : nil,
                transactionCount: lockedAnalytics.transactions ? TransactionCountViewItem(chart: .locked, volume: .locked, rank: .locked) : nil,
                holders: lockedAnalytics.holders ? .locked : nil,
                tvl: lockedAnalytics.tvl ? TvlViewItem(chart: .locked, rank: .locked, ratio: .locked) : nil,
                revenue: lockedAnalytics.revenue ? RevenueViewItem(value: .locked, rank: .locked) : nil,
                reports: lockedAnalytics.reports ? .locked : nil,
                investors: lockedAnalytics.fundsInvested ? .locked : nil,
                treasuries: lockedAnalytics.treasuries ? .locked : nil,
                auditAddresses: service.auditAddresses != nil ? .locked : nil
        )
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

    var coin: Coin {
        service.coin
    }

    func onLoad() {
        service.sync()
    }

    func onTapRetry() {
        service.sync()
    }

}

extension CoinAnalyticsViewModel {

    struct ViewItem {
        let lockInfo: Bool
        let cexVolume: RankCardViewItem?
        let dexVolume: RankCardViewItem?
        let dexLiquidity: RankCardViewItem?
        let activeAddresses: RankCardViewItem?
        let transactionCount: TransactionCountViewItem?
        let holders: Lockable<HoldersViewItem>?
        let tvl: TvlViewItem?
        let revenue: RevenueViewItem?
        let reports: Lockable<String>?
        let investors: Lockable<String>?
        let treasuries: Lockable<String>?
        let auditAddresses: Lockable<[String]>?

        var isEmpty: Bool {
            let items: [Any?] = [cexVolume, dexVolume, dexLiquidity, activeAddresses, transactionCount, holders, tvl, revenue, reports, investors, treasuries]
            return items.compactMap { $0 }.isEmpty
        }
    }

    struct ChartViewItem {
        let value: String
        let chartData: ChartData
    }

    struct RankCardViewItem {
        let chart: Lockable<ChartViewItem>
        let rank: Lockable<String>?
    }

    struct TransactionCountViewItem {
        let chart: Lockable<ChartViewItem>
        let volume: Lockable<String>?
        let rank: Lockable<String>?
    }

    struct HoldersViewItem {
        let value: String?
        let holderViewItems: [HolderViewItem]
    }

    struct HolderViewItem {
        let blockchainType: BlockchainType
        let imageUrl: String
        let name: String
        let value: String?
        let percent: Decimal
    }

    struct TvlViewItem {
        let chart: Lockable<ChartViewItem>
        let rank: Lockable<String>?
        let ratio: Lockable<String>?
    }

    struct RevenueViewItem {
        let value: Lockable<String>
        let rank: Lockable<String>?
    }

    enum ChartPreviewValuePostfix {
        case currency
        case coin
        case noPostfix
    }

}

enum Lockable<T> {
    case locked
    case unlocked(value: T)

    var isLocked: Bool {
        switch self {
        case .locked: return true
        case .unlocked: return false
        }
    }

    func lockableValue<P>(mapper: (T) -> P) -> Lockable<P> {
        switch self {
        case .locked: return .locked
        case .unlocked(let value): return .unlocked(value: mapper(value))
        }
    }

}
