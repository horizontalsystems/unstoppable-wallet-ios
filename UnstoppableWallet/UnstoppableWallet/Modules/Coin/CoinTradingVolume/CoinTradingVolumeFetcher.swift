import XRatesKit
import RxSwift
import Foundation
import CoinKit

class CoinTradingVolumeFetcher {
    private let rateManager: IRateManager
    private let coinType: CoinType
    private let coinTitle: String

    init(rateManager: IRateManager, coinType: CoinType, coinTitle: String) {
        self.rateManager = rateManager
        self.coinType = coinType
        self.coinTitle = coinTitle
    }

}

extension CoinTradingVolumeFetcher: IMetricChartConfiguration {
    var title: String { "coin_page.trading_volume".localized }
    var description: String? { "coin_page.trading_volume.description".localized(coinTitle) }
    var poweredBy: String { "CoinGecko API" }

    var valueType: MetricChartModule.ValueType {
        .compactCurrencyValue
    }

}

extension CoinTradingVolumeFetcher: IMetricChartFetcher {

    func fetchSingle(currencyCode: String, timePeriod: TimePeriod) -> Single<[MetricChartModule.Item]> {
        rateManager
                .coinMarketPointsSingle(coinType: coinType, currencyCode: currencyCode, fetchDiffPeriod: timePeriod)
                .map { points in
                    points.map {
                        MetricChartModule.Item(value: $0.volume24h, timestamp: TimeInterval($0.timestamp))
                    }
                }
    }

}
