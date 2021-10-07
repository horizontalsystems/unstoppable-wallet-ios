import CoinKit
import XRatesKit
import Foundation
import RxSwift

protocol IRateManager {
    func refresh(currencyCode: String)
    
    func globalMarketInfoSingle(currencyCode: String, period: TimePeriod) -> Single<GlobalCoinMarket>
    func topMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]>
    func overviewTopMarketsSingle(type: RateManager.OverviewType, currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]>
    func coinsMarketSingle(currencyCode: String, coinTypes: [CoinKit.CoinType]) -> Single<[CoinMarket]>
    func searchCoins(text: String) -> [CoinData]
    func latestRate(coinType: CoinKit.CoinType, currencyCode: String) -> LatestRate?
    func latestRateMap(coinTypes: [CoinKit.CoinType], currencyCode: String) -> [CoinKit.CoinType: LatestRate]
    func latestRateObservable(coinType: CoinKit.CoinType, currencyCode: String) -> Observable<LatestRate>
    func latestRatesObservable(coinTypes: [CoinKit.CoinType], currencyCode: String) -> Observable<[CoinKit.CoinType: LatestRate]>
    func historicalRate(coinType: CoinKit.CoinType, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal>
    func historicalRate(coinType: CoinKit.CoinType, currencyCode: String, timestamp: TimeInterval) -> Decimal?
    func chartInfo(coinType: CoinKit.CoinType, currencyCode: String, chartType: ChartType) -> ChartInfo?
    func chartInfoObservable(coinType: CoinKit.CoinType, currencyCode: String, chartType: ChartType) -> Observable<ChartInfo>
    func coinMarketInfoSingle(coinType: CoinKit.CoinType, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo>
    func globalMarketInfoPointsSingle(currencyCode: String, timePeriod: TimePeriod) -> Single<[GlobalCoinMarketPoint]>
    func topDefiTvlSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemsCount: Int, chain: String?) -> Single<[DefiTvl]>
    func defiTvlPoints(coinType: CoinKit.CoinType, currencyCode: String, fetchDiffPeriod: TimePeriod) -> Single<[DefiTvlPoint]>
    func defiTvl(coinType: CoinKit.CoinType, currencyCode: String) -> Single<DefiTvl?>
    func coinMarketPointsSingle(coinType: CoinKit.CoinType, currencyCode: String, fetchDiffPeriod: TimePeriod) -> Single<[CoinMarketPoint]>
    func topTokenHoldersSingle(coinType: CoinKit.CoinType, itemsCount: Int) -> Single<[TokenHolder]>
    func auditReportsSingle(coinType: CoinKit.CoinType) -> Single<[Auditor]>
    func coinTypes(for category: String) -> [CoinKit.CoinType]
}
