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

    init(service: CoinAnalyticsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinAnalyticsService.Item>) {
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case .completed(let item):
            viewItemRelay.accept(viewItem(item: item))
//            viewItemRelay.accept(lockedViewItem(item: item))
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        }
    }

    private func chartViewItem(data: CoinAnalyticsService.ProData, currentValueType: CoinProChartModule.ChartValueType, chartPreviewValuePostfix: ChartPreviewValuePostfix) -> ChartViewItem? {
        switch data {
        case .empty: return nil
        case .completed(let values):
            guard let first = values.first, let last = values.last else {
                return nil
            }

            let chartItems = values.map {
                ChartItem(timestamp: $0.timestamp).added(name: .rate, value: $0.value)
            }

            let chartData = ChartData(items: chartItems, startTimestamp: first.timestamp, endTimestamp: last.timestamp)

            var value: Decimal

            switch currentValueType {
            case .last: value = last.value
            case .cumulative: value = values.map { $0.value }.reduce(0, +)
            }

            let valueString: String?

            switch chartPreviewValuePostfix {
            case .currency: valueString = ValueFormatter.instance.formatShort(currency: service.currency, value: value)
            case .coin: valueString = ValueFormatter.instance.formatShort(value: value).map { [$0, coin.code].joined(separator: " ") }
            case .noPostfix: valueString = ValueFormatter.instance.formatShort(value: value)
            }

            guard let valueString else {
                return nil
            }

            return ChartViewItem(value: valueString, chartData: chartData)
        }
    }

    private func rankCardViewItem(data: CoinAnalyticsService.ProData, type: CoinProChartModule.ChartValueType, postfix: ChartPreviewValuePostfix, rank: Int?) -> Lockable<RankCardViewItem>? {
        guard let chartViewItem = chartViewItem(data: data, currentValueType: type, chartPreviewValuePostfix: postfix), let rank else {
            return nil
        }

        return .unlocked(value: RankCardViewItem(chart: chartViewItem, rank: "#\(rank)"))
    }

    private func transactionCountViewItem(data: CoinAnalyticsService.ProData, volumeData: CoinAnalyticsService.ProData, rank: Int?) -> Lockable<TransactionCountViewItem>? {
        guard let chartViewItem = chartViewItem(data: data, currentValueType: .cumulative, chartPreviewValuePostfix: .noPostfix),
              let volumeChartViewItem = self.chartViewItem(data: volumeData, currentValueType: .cumulative, chartPreviewValuePostfix: .coin),
              let rank else {
            return nil
        }

        return .unlocked(value: TransactionCountViewItem(chart: chartViewItem, rank: "#\(rank)", volume: volumeChartViewItem.value))
    }

    private func tvlViewItem(tvls: [ChartPoint]?, rank: Int?, ratio: Decimal?) -> Lockable<TvlViewItem>? {
        guard let chartViewItem = chartViewItem(data: tvls.flatMap { .completed($0) } ?? .empty, currentValueType: .last, chartPreviewValuePostfix: .currency),
              let ratio = ratio.flatMap({ ratioFormatter.string(from: $0 as NSNumber) }),
              let rank else {
            return nil
        }

        return .unlocked(value: TvlViewItem(chart: chartViewItem, rank: "#\(rank)", ratio: ratio))
    }

    private func viewItem(item: CoinAnalyticsService.Item) -> ViewItem {
        ViewItem(
                lockInfo: false,
                cexVolume: rankCardViewItem(
                        data: item.analytics.dexVolumes,
                        type: .cumulative,
                        postfix: .currency,
                        rank: 15
                ),
                dexVolume: rankCardViewItem(
                        data: item.analytics.dexVolumes,
                        type: .cumulative,
                        postfix: .currency,
                        rank: 25
                ),
                dexLiquidity: rankCardViewItem(
                        data: item.analytics.dexLiquidity,
                        type: .last,
                        postfix: .currency,
                        rank: 35
                ),
                activeAddresses: rankCardViewItem(
                        data: item.analytics.activeAddresses,
                        type: .cumulative,
                        postfix: .noPostfix,
                        rank: 45
                ),
                transactionCount: transactionCountViewItem(
                        data: item.analytics.txCount,
                        volumeData: item.analytics.txVolume,
                        rank: 55
                ),
                tvl: tvlViewItem(
                        tvls: item.tvls,
                        rank: item.marketInfoDetails.tvlRank,
                        ratio: item.marketInfoDetails.tvlRatio
                ),
                revenue: .unlocked(value: RevenueViewItem(value: "$2.46M", rank: "#3")),
                investors: item.marketInfoDetails.totalFundsInvested
                        .flatMap { ValueFormatter.instance.formatShort(currency: service.usdCurrency, value: $0) }
                        .map { .unlocked(value: $0) },
                treasuries: item.marketInfoDetails.totalTreasuries
                        .flatMap { ValueFormatter.instance.formatShort(currency: service.currency, value: $0) }
                        .map { .unlocked(value: $0) },
                reports: item.marketInfoDetails.reportsCount == 0 ? nil : .unlocked(value: "\(item.marketInfoDetails.reportsCount)"),
                auditAddresses: service.auditAddresses.count == 0 ? nil : .unlocked(value: service.auditAddresses)
        )
    }

    private func lockedViewItem(item: CoinAnalyticsService.Item) -> ViewItem {
        ViewItem(
                lockInfo: true,
                cexVolume: .locked,
                dexVolume: .locked,
                dexLiquidity: .locked,
                activeAddresses: .locked,
                transactionCount: .locked,
                tvl: .locked,
                revenue: .locked,
                investors: .locked,
                treasuries: .locked,
                reports: .locked,
                auditAddresses: .locked
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
        let cexVolume: Lockable<RankCardViewItem>?
        let dexVolume: Lockable<RankCardViewItem>?
        let dexLiquidity: Lockable<RankCardViewItem>?
        let activeAddresses: Lockable<RankCardViewItem>?
        let transactionCount: Lockable<TransactionCountViewItem>?
        let tvl: Lockable<TvlViewItem>?
        let revenue: Lockable<RevenueViewItem>?
        let investors: Lockable<String>?
        let treasuries: Lockable<String>?
        let reports: Lockable<String>?
        let auditAddresses: Lockable<[String]>?
    }

    struct ChartViewItem {
        let value: String
        let chartData: ChartData
    }

    struct RankCardViewItem {
        let chart: ChartViewItem
        let rank: String
    }

    struct TransactionCountViewItem {
        let chart: ChartViewItem
        let rank: String
        let volume: String
    }

    struct TvlViewItem {
        let chart: ChartViewItem
        let rank: String
        let ratio: String
    }

    struct RevenueViewItem {
        let value: String
        let rank: String
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
