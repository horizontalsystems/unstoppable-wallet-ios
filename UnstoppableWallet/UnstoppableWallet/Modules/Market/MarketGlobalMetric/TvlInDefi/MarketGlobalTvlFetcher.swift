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

extension MarketGlobalTvlFetcher: IMetricChartFetcher {

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue(currencyKit.baseCurrency)
    }

    var needUpdateObservable: Observable<()> {
        needUpdateRelay.asObservable()
    }

    func fetchSingle(interval: HsTimePeriod) -> RxSwift.Single<MetricChartModule.ItemData> {
        marketKit
                .marketInfoGlobalTvlSingle(platform: service.marketPlatformField.chain, currencyCode: currencyKit.baseCurrency.code, timePeriod: interval)
                .map { points in
                    let items = points.map { point -> MetricChartModule.Item in
                        MetricChartModule.Item(value: point.value, timestamp: point.timestamp)
                    }

                    return MetricChartModule.ItemData(items: items, type: .regular)
                }
    }

}
