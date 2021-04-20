import RxSwift
import RxCocoa
import XRatesKit
import Chart

class MarketMetricsViewModel {
    private let service: MarketMetricsService
    private let disposeBag = DisposeBag()

    private let metricsRelay = BehaviorRelay<MarketMetrics?>(value: nil)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: MarketMetricsService) {
        self.service = service

        subscribe(disposeBag, service.globalMarketInfoObservable) { [weak self] in self?.sync(marketInfo: $0) }
    }

    private func sync(marketInfo: DataStatus<GlobalCoinMarket>) {
        metricsRelay.accept(marketInfo.data.flatMap { marketMetrics(marketInfo: $0) })
        isLoadingRelay.accept(marketInfo.isLoading && metricsRelay.value == nil)
        errorRelay.accept(marketInfo.error.map { _ in "market.sync_error".localized } )
    }

    private func chartData(points: [(timestamp: TimeInterval, rate: Decimal)]) -> (data: ChartData?, trend: MovementTrend) {
        guard let first = points.first, let last = points.last else {
            return (data: nil, trend: .neutral)
        }

        let chartItems: [ChartItem] = points.map {
            let item = ChartItem(timestamp: $0.timestamp)
            item.add(name: .rate, value: $0.rate)
            return item
        }

        var movementTrend = MovementTrend.neutral

        if first.rate > last.rate {
            movementTrend = .down
        } else if first.rate < last.rate {
            movementTrend = .up
        }

        return (data: ChartData(items: chartItems, startTimestamp: first.timestamp, endTimestamp: last.timestamp), trend: movementTrend)
    }

    private func marketMetrics(marketInfo: GlobalCoinMarket) -> MarketMetrics? {
        let formatter = CurrencyCompactFormatter.instance

        guard let totalMarketCap = formatter.format(currency: service.currency, value: marketInfo.marketCap, fractionMaximumFractionDigits: 2),
              let volume24h = formatter.format(currency: service.currency, value: marketInfo.volume24h),
              let defiCap = formatter.format(currency: service.currency, value: marketInfo.defiMarketCap),
              let defiTvl = formatter.format(currency: service.currency, value: marketInfo.defiTvl) else {

            return nil
        }

        let btcDominance = ValueFormatter.instance.format(percentValue: marketInfo.btcDominance, signed: false)

        let volumeChart = chartData(points: marketInfo.globalCoinMarketPoints.map { (timestamp: $0.timestamp, rate: $0.volume24h) })
        let btcDominanceChart = chartData(points: marketInfo.globalCoinMarketPoints.map { (timestamp: $0.timestamp, rate: $0.dominanceBtc) })
        let defiCapChart = chartData(points: marketInfo.globalCoinMarketPoints.map { (timestamp: $0.timestamp, rate: $0.marketCapDefi) })
        let defiTvlChart = chartData(points: marketInfo.globalCoinMarketPoints.map { (timestamp: $0.timestamp, rate: $0.tvl) })

        return MarketMetrics(
            totalMarketCap: MetricData(value: totalMarketCap, diff: marketInfo.marketCapDiff24h),
            volume24h: ChartMetricData(value: volume24h, diff: marketInfo.volume24hDiff24h, chartData: volumeChart.data, chartTrend: volumeChart.trend),
            btcDominance: ChartMetricData(value: btcDominance, diff: marketInfo.btcDominanceDiff24h, chartData: btcDominanceChart.data, chartTrend: btcDominanceChart.trend),
            defiCap: ChartMetricData(value: defiCap, diff: marketInfo.defiMarketCapDiff24h, chartData: defiCapChart.data, chartTrend: defiCapChart.trend),
            defiTvl: ChartMetricData(value: defiTvl, diff: marketInfo.defiTvlDiff24h, chartData: defiTvlChart.data, chartTrend: defiTvlChart.trend))
    }

}

extension MarketMetricsViewModel {

    var metricsDriver: Driver<MarketMetrics?> {
        metricsRelay.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketMetricsViewModel {

    struct MetricData {
        let value: String?
        let diff: Decimal?
    }

    struct ChartMetricData {
        let value: String?
        let diff: Decimal?
        let chartData: ChartData?
        let chartTrend: MovementTrend
    }

    struct MarketMetrics {
        let totalMarketCap: MetricData
        let volume24h: ChartMetricData
        let btcDominance: ChartMetricData
        let defiCap: ChartMetricData
        let defiTvl: ChartMetricData
    }

}
