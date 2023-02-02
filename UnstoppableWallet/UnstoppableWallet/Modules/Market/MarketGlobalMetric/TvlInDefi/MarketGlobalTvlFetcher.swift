import RxSwift
import RxCocoa
import Foundation
import MarketKit
import CurrencyKit
import Chart

class MarketGlobalTvlFetcher {
    private let disposeBag = DisposeBag()
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let service: MarketGlobalTvlMetricService

    private let needUpdateRelay = PublishRelay<()>()

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, marketGlobalTvlPlatformService: MarketGlobalTvlMetricService) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
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
    var poweredBy: String? { "DefiLlama API" }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyKit.baseCurrency)
    }

}

extension MarketGlobalTvlFetcher: IMetricChartFetcher {

    var needUpdateObservable: Observable<()> {
        needUpdateRelay.asObservable()
    }

    func fetchSingle(interval: HsTimePeriod) -> RxSwift.Single<[MetricChartModule.Item]> {
        marketKit
                .marketInfoGlobalTvlSingle(platform: service.marketPlatformField.chain, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
                .map { points in
                    points.map { point -> MetricChartModule.Item in
                        MetricChartModule.Item(value: point.value, timestamp: point.timestamp)
                    }
                }
    }

}
