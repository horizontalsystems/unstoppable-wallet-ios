import RxSwift
import RxCocoa
import XRatesKit

class MarketMetricsViewModel {
    private let disposeBag = DisposeBag()

    public let service: MarketMetricsService

    private let metricsRelay = BehaviorRelay<MarketMetrics?>(value: nil)

    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var isLoading: Bool = false

    private let errorRelay = BehaviorRelay<String?>(value: nil)
    private var error: String?

    init(service: MarketMetricsService) {
        self.service = service

        subscribe(disposeBag, service.globalMarketInfoObservable) { [weak self] in self?.sync(marketInfo: $0) }
    }

    private func sync(marketInfo: DataStatus<GlobalCoinMarket>) {
        if let data = marketInfo.data {

            metricsRelay.accept(marketMetrics(marketInfo: data))
        }
        isLoadingRelay.accept(marketInfo.isLoading)
        errorRelay.accept(marketInfo.error?.smartDescription)
    }

    private func marketMetrics(marketInfo: GlobalCoinMarket) -> MarketMetrics? {
        let formatter = CurrencyCompactFormatter.instance

        guard let totalMarketCap = formatter.format(currency: service.currency, value: marketInfo.marketCap),
              let volume24h = formatter.format(currency: service.currency, value: marketInfo.volume24h),
              let defiCap = formatter.format(currency: service.currency, value: marketInfo.defiMarketCap),
              let defiTvl = formatter.format(currency: service.currency, value: marketInfo.defiTvl) else {

            return nil
        }

        return MarketMetrics(
            totalMarketCap: MetricData(value: totalMarketCap, diff: marketInfo.marketCapDiff24h),
            volume24h: MetricData(value: volume24h, diff: marketInfo.volume24hDiff24h),
            btcDominance: MetricData(value: "\(marketInfo.btcDominance)%", diff: marketInfo.btcDominanceDiff24h),
            defiCap: MetricData(value: defiCap, diff: marketInfo.defiMarketCapDiff24h),
            defiTvl: MetricData(value: defiTvl, diff: marketInfo.defiTvlDiff24h))
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

    public func refresh() {
        service.refresh()
    }

}

extension MarketMetricsViewModel {

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
