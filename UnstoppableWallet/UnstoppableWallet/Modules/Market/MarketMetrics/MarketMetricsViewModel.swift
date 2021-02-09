import RxSwift
import RxCocoa
import XRatesKit

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

    private func marketMetrics(marketInfo: GlobalCoinMarket) -> MarketMetrics? {
        let formatter = CurrencyCompactFormatter.instance

        guard let totalMarketCap = formatter.format(currency: service.currency, value: marketInfo.marketCap),
              let volume24h = formatter.format(currency: service.currency, value: marketInfo.volume24h),
              let defiCap = formatter.format(currency: service.currency, value: marketInfo.defiMarketCap) else {
//              let defiTvl = formatter.format(currency: service.currency, value: marketInfo.defiTvl) else {

            return nil
        }

        let btcDominance = ValueFormatter.instance.format(percentValue: marketInfo.btcDominance, signed: false)
        return MarketMetrics(

            totalMarketCap: MetricData(value: totalMarketCap, diff: marketInfo.marketCapDiff24h),
            volume24h: MetricData(value: volume24h, diff: marketInfo.volume24hDiff24h),
            btcDominance: MetricData(value: btcDominance, diff: marketInfo.btcDominanceDiff24h),
            defiCap: MetricData(value: defiCap, diff: nil),
            defiTvl: MetricData(value: nil, diff: nil))
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

    struct MarketMetrics {
        let totalMarketCap: MetricData
        let volume24h: MetricData
        let btcDominance: MetricData
        let defiCap: MetricData
        let defiTvl: MetricData
    }

}
