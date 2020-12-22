import Foundation
import RxSwift
import RxRelay

class MarketMetricsService {
    private let disposeBag = DisposeBag()

    private let marketMetricsRelay = BehaviorRelay<DataStatus<MarketMetrics>>(value: .loading)
    private var marketMetrics: DataStatus<MarketMetrics> = .loading

    init() {
        fetchMarketMetrics()
    }

    private func fetchMarketMetrics() {
        let metrics = MarketMetrics(
                totalMarketCap: MetricData(value: "$498.61B", diff: -1.2413),
                volume24h: MetricData(value: "$167.84B", diff: -0.1591),
                btcDominance: MetricData(value: "64.09%", diff: -0.691),
                defiCap: MetricData(value: "$16.31B", diff: 0.0291),
                defiTvl: MetricData(value: "$17.5B", diff: 1.2413))

        marketMetricsRelay.accept(.completed(metrics))
    }

}

extension MarketMetricsService {

    public let marketMetricsObservable: Observable<DataStatus<MarketMetrics>> {
        marketMetricsRelay.asObservable()
    }

    public func refresh() {
        fetchMarketMetrics()
    }

}
