import Foundation
import RxSwift
import RxRelay

class MarketMetricsService {
    private let disposeBag = DisposeBag()
    private var timer: Timer?

    private let marketMetricsRelay = BehaviorRelay<DataStatus<MarketMetrics>>(value: .loading)
    private var marketMetrics: DataStatus<MarketMetrics> = .loading

    private var currentStubValue = 0
    private let stubMetricsArray = [
        MarketMetrics(
            totalMarketCap: MetricData(value: "$298.61B", diff: -1.2413),
            volume24h: MetricData(value: "$167.84B", diff: -0.1591),
            btcDominance: MetricData(value: "64.09%", diff: -0.691),
            defiCap: MetricData(value: "$16.31B", diff: 0.0291),
            defiTvl: MetricData(value: "$17.5B", diff: 1.2413)),
        MarketMetrics(
            totalMarketCap: MetricData(value: "$398.61B", diff: 0.4413),
            volume24h: MetricData(value: "$67.84B", diff: 1.1591),
            btcDominance: MetricData(value: "64.09%", diff: 0.691),
            defiCap: MetricData(value: "$16.31B", diff: 0.5291),
            defiTvl: MetricData(value: "$37.5B", diff: 0.2413))
    ]

    init() {
        fetchMarketMetrics()
    }

    private func fetchMarketMetrics() {
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.setMetrics()
        }
    }

    private func setMetrics() {
        DispatchQueue.main.asyncAfter(deadline: .now()) { () -> () in
            self.marketMetricsRelay.accept(.completed(self.stubMetricsArray[self.currentStubValue % 2]))
            self.currentStubValue += 1
        }
    }
}

extension MarketMetricsService {

    public var marketMetricsObservable: Observable<DataStatus<MarketMetrics>> {
        marketMetricsRelay.asObservable()
    }

    public func refresh() {
        fetchMarketMetrics()
    }

}

extension MarketMetricsService {

    struct MetricData {
        let value: String
        let diff: Decimal
    }

    struct MarketMetrics {
        let totalMarketCap: MetricData
        let volume24h: MetricData
        let btcDominance: MetricData
        let defiCap: MetricData
        let defiTvl: MetricData
    }

}
