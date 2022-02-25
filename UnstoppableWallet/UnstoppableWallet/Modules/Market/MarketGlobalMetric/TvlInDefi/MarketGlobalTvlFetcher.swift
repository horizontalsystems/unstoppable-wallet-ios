import RxSwift
import RxCocoa
import Foundation
import MarketKit
import Chart

class MarketGlobalTvlFetcher {
    private let disposeBag = DisposeBag()
    private let marketKit: MarketKit.Kit
    private let service: MarketGlobalTvlMetricService

    private let needUpdateRelay = PublishRelay<()>()

    init(marketKit: MarketKit.Kit, marketGlobalTvlPlatformService: MarketGlobalTvlMetricService) {
        self.marketKit = marketKit
        service = marketGlobalTvlPlatformService

        subscribe(disposeBag, service.marketPlatformObservable) { [weak self] _ in self?.needUpdate() }
    }

    private func needUpdate() {
        needUpdateRelay.accept(())
    }

}

extension MarketGlobalTvlFetcher: IMetricChartConfiguration {
    var title: String { MarketGlobalModule.MetricsType.tvlInDefi.title }
    var description: String? { MarketGlobalModule.MetricsType.tvlInDefi.description }
    var poweredBy: String { "DefiLlama API" }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue
    }

}

extension MarketGlobalTvlFetcher: IMetricChartFetcher {

    var needUpdateObservable: Observable<()> {
        needUpdateRelay.asObservable()
    }

    func fetchSingle(currencyCode: String, interval: HsTimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
        marketKit
                .marketInfoGlobalTvlSingle(platform: service.marketPlatformField.chain, currencyCode: currencyCode, timePeriod: interval)
                .map { points in
                    points.map { point -> MetricChartModule.Item in
                        MetricChartModule.Item(value: point.value, timestamp: point.timestamp)
                    }
                }
    }

}
