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
    private let emptyViewRelay = BehaviorRelay<Bool>(value: false)

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
            emptyViewRelay.accept(false)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
            emptyViewRelay.accept(false)
        case .preview(let analyticsPreview):
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
        case .success(let analytics):
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
                chart: .regular(value: chartViewItem),
                rank: rank.map { .regular(value: rankString(value: $0)) }
        )
    }

    private func transactionCountViewItem(points: [ChartPoint]?, volume: Decimal?, rank: Int?) -> TransactionCountViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, type: .cumulative, postfix: .noPostfix) else {
            return nil
        }

        return TransactionCountViewItem(
                chart: .regular(value: chartViewItem),
                volume: volume.flatMap { ValueFormatter.instance.formatShort(value: $0) }.map { .regular(value: [$0, coin.code].joined(separator: " ")) },
                rank: rank.map { .regular(value: rankString(value: $0)) }
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

        let blockchains = service.blockchains(uids: holderBlockchains.filter { $0.holdersCount > 0 }.map { $0.uid })

        let items = holderBlockchains.sorted { $0.holdersCount > $1.holdersCount }.compactMap { holderBlockchain -> Item? in
            guard let blockchain = blockchains.first(where: { $0.uid == holderBlockchain.uid }) else {
                return nil
            }

            return Item(blockchain: blockchain, count: holderBlockchain.holdersCount)
        }

        guard !items.isEmpty else {
            return nil
        }

        let total = items.map { $0.count }.reduce(0, +)

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

    private func tvlViewItem(points: [ChartPoint]?, rank: Int?, ratio: Decimal?) -> TvlViewItem? {
        guard let points, let chartViewItem = chartViewItem(points: points, type: .last, postfix: .currency) else {
            return nil
        }

        return TvlViewItem(
                chart: .regular(value: chartViewItem),
                rank: rank.map { .regular(value: rankString(value: $0)) },
                ratio: ratio.flatMap { ratioFormatter.string(from: $0 as NSNumber) }.map { .regular(value: $0) }
        )
    }

    private func revenueViewItem(value: Decimal?, rank: Int?) -> RevenueViewItem? {
        guard let value, let formattedValue = ValueFormatter.instance.formatShort(currency: service.currency, value: value) else {
            return nil
        }

        return RevenueViewItem(
                value: .regular(value: formattedValue),
                rank: rank.map { .regular(value: rankString(value: $0)) }
        )
    }

    private func viewItem(analytics: Analytics) -> ViewItem {
        ViewItem(
                lockInfo: false,
                cexVolume: rankCardViewItem(
                        points: analytics.cexVolume?.chartPoints,
                        type: .cumulative,
                        postfix: .currency,
                        rank: analytics.cexVolume?.rank30d
                ),
                dexVolume: rankCardViewItem(
                        points: analytics.dexVolume?.chartPoints,
                        type: .cumulative,
                        postfix: .currency,
                        rank: analytics.dexVolume?.rank30d
                ),
                dexLiquidity: rankCardViewItem(
                        points: analytics.dexLiquidity?.chartPoints,
                        type: .last,
                        postfix: .currency,
                        rank: analytics.dexLiquidity?.rank
                ),
                activeAddresses: rankCardViewItem(
                        points: analytics.addresses?.chartPoints,
                        value: analytics.addresses?.count30d,
                        type: .cumulative,
                        postfix: .noPostfix,
                        rank: analytics.addresses?.rank30d
                ),
                transactionCount: transactionCountViewItem(
                        points: analytics.transactions?.chartPoints,
                        volume: analytics.transactions?.volume30d,
                        rank: analytics.transactions?.rank30d
                ),
                holders: holdersViewItem(holderBlockchains: analytics.holders),
                tvl: tvlViewItem(
                        points: analytics.tvl?.chartPoints,
                        rank: analytics.tvl?.rank,
                        ratio: analytics.tvl?.ratio
                ),
                revenue: revenueViewItem(
                        value: analytics.revenue?.value30d,
                        rank: analytics.revenue?.rank30d
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
                        .map { .regular(value: $0) }
        )
    }

    private func previewViewItem(analyticsPreview data: AnalyticsPreview) -> ViewItem {
        ViewItem(
                lockInfo: true,
                cexVolume: data.cexVolume ? RankCardViewItem(chart: .preview, rank: data.cexVolumeRank30d ? .preview : nil) : nil,
                dexVolume: data.dexVolume ? RankCardViewItem(chart: .preview, rank: data.dexVolumeRank30d ? .preview : nil) : nil,
                dexLiquidity: data.dexLiquidity ? RankCardViewItem(chart: .preview, rank: data.dexLiquidityRank ? .preview : nil) : nil,
                activeAddresses: data.addresses ? RankCardViewItem(chart: .preview, rank: data.addressesRank30d ? .preview : nil) : nil,
                transactionCount: data.transactions ? TransactionCountViewItem(chart: .preview, volume: data.transactionsVolume30d ? .preview : nil, rank: data.transactionsRank30d ? .preview : nil) : nil,
                holders: data.holders ? .preview : nil,
                tvl: data.tvl ? TvlViewItem(chart: .preview, rank: data.tvlRank ? .preview : nil, ratio: data.tvlRatio ? .preview : nil) : nil,
                revenue: data.revenue ? RevenueViewItem(value: .preview, rank: data.revenueRank30d ? .preview : nil) : nil,
                reports: data.reports ? .preview : nil,
                investors: data.fundsInvested ? .preview : nil,
                treasuries: data.treasuries ? .preview : nil,
                auditAddresses: service.auditAddresses != nil ? .preview : nil
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

    var emptyViewDriver: Driver<Bool> {
        emptyViewRelay.asDriver()
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
        let holders: Previewable<HoldersViewItem>?
        let tvl: TvlViewItem?
        let revenue: RevenueViewItem?
        let reports: Previewable<String>?
        let investors: Previewable<String>?
        let treasuries: Previewable<String>?
        let auditAddresses: Previewable<[String]>?

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
        let chart: Previewable<ChartViewItem>
        let rank: Previewable<String>?
    }

    struct TransactionCountViewItem {
        let chart: Previewable<ChartViewItem>
        let volume: Previewable<String>?
        let rank: Previewable<String>?
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

    struct TvlViewItem {
        let chart: Previewable<ChartViewItem>
        let rank: Previewable<String>?
        let ratio: Previewable<String>?
    }

    struct RevenueViewItem {
        let value: Previewable<String>
        let rank: Previewable<String>?
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
        case .regular(let value): return .regular(value: mapper(value))
        }
    }

}
