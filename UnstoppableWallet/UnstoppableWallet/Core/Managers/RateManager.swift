import Foundation
import RxSwift
import CurrencyKit
import XRatesKit
import CoinKit

class RateManager {
    private let disposeBag = DisposeBag()

    private let walletManager: WalletManager
    private let rateCoinMapper: IRateCoinMapper
    private let feeCoinProvider: FeeCoinProvider
    private let appConfigProvider: IAppConfigProvider

    private let kit: XRatesKit

    init(walletManager: WalletManager, currencyKit: CurrencyKit.Kit, rateCoinMapper: IRateCoinMapper, feeCoinProvider: FeeCoinProvider, appConfigProvider: IAppConfigProvider) {
        self.walletManager = walletManager
        self.rateCoinMapper = rateCoinMapper
        self.feeCoinProvider = feeCoinProvider
        self.appConfigProvider = appConfigProvider

        kit = XRatesKit.instance(
                currencyCode: currencyKit.baseCurrency.code,
                coinMarketCapApiKey: appConfigProvider.coinMarketCapApiKey,
                cryptoCompareApiKey: appConfigProvider.cryptoCompareApiKey,
                defiYieldApiKey: appConfigProvider.defiYieldApiKey,
                uniswapSubgraphUrl: appConfigProvider.uniswapSubgraphUrl,
                indicatorPointCount: 50,
                marketInfoExpirationInterval: 60,
                topMarketsCount: 100,
                providerCoinsUrl: appConfigProvider.providerCoinsUrl,
                coinsUrl: appConfigProvider.coinsUrl,
                minLogLevel: .error
        )
    }

}

extension RateManager: IRateManager {

    func refresh(currencyCode: String) {
        kit.refresh(currencyCode: currencyCode)
    }

    func globalMarketInfoSingle(currencyCode: String, period: TimePeriod) -> Single<GlobalCoinMarket> {
        kit.globalMarketInfoSingle(currencyCode: currencyCode, timePeriod: period)
    }

    func topMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]> {
        kit.topMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemsCount: itemCount)
    }

    func coinsMarketSingle(currencyCode: String, coinTypes: [CoinType]) -> Single<[CoinMarket]> {
        kit.favorites(currencyCode: currencyCode, coinTypes: coinTypes)
    }

    func searchCoins(text: String) -> [CoinData] {
        kit.search(text: text)
    }

    func latestRate(coinType: CoinType, currencyCode: String) -> LatestRate? {
        kit.latestRate(coinType: coinType, currencyCode: currencyCode)
    }

    func latestRateMap(coinTypes: [CoinType], currencyCode: String) -> [CoinType: LatestRate] {
        kit.latestRateMap(coinTypes: coinTypes, currencyCode: currencyCode)
    }

    func latestRateObservable(coinType: CoinType, currencyCode: String) -> Observable<LatestRate> {
        kit.latestRateObservable(coinType: coinType, currencyCode: currencyCode)
    }

    func latestRatesObservable(coinTypes: [CoinType], currencyCode: String) -> Observable<[CoinType: LatestRate]> {
        kit.latestRatesObservable(coinTypes: coinTypes, currencyCode: currencyCode)
    }

    func historicalRate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        kit.historicalRateSingle(coinType: coinType, currencyCode: currencyCode, timestamp: timestamp)
    }

    func historicalRate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Decimal? {
        kit.historicalRate(coinType: coinType, currencyCode: currencyCode, timestamp: timestamp)
    }

    func chartInfo(coinType: CoinType, currencyCode: String, chartType: ChartType) -> ChartInfo? {
        kit.chartInfo(coinType: coinType, currencyCode: currencyCode, chartType: chartType)
    }

    func chartInfoObservable(coinType: CoinType, currencyCode: String, chartType: ChartType) -> Observable<ChartInfo> {
        kit.chartInfoObservable(coinType: coinType, currencyCode: currencyCode, chartType: chartType)
    }

    func coinMarketInfoSingle(coinType: CoinType, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo> {
        kit.coinMarketInfoSingle(coinType: coinType, currencyCode: currencyCode, rateDiffTimePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes)
    }

    func globalMarketInfoPointsSingle(currencyCode: String, timePeriod: TimePeriod) -> Single<[GlobalCoinMarketPoint]> {
        kit.globalMarketInfoPointsSingle(currencyCode: currencyCode, timePeriod: timePeriod)
    }

    func topDefiTvlSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemsCount: Int, chain: String?) -> Single<[DefiTvl]> {
        kit.topDefiTvlSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemsCount: itemsCount, chain: chain)
    }

    public func defiTvlPoints(coinType: CoinType, currencyCode: String, fetchDiffPeriod: TimePeriod) -> Single<[DefiTvlPoint]> {
        kit.defiTvlPoints(coinType: coinType, currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod)
    }

    public func defiTvl(coinType: CoinType, currencyCode: String) -> Single<DefiTvl?> {
        kit.defiTvl(coinType: coinType, currencyCode: currencyCode)
    }

    func coinMarketPointsSingle(coinType: CoinType, currencyCode: String, fetchDiffPeriod: TimePeriod) -> Single<[CoinMarketPoint]> {
        kit.coinMarketPointsSingle(coinType: coinType, currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod)
    }

    func topTokenHoldersSingle(coinType: CoinType, itemsCount: Int) -> Single<[TokenHolder]> {
        kit.topTokenHoldersSingle(coinType: coinType, itemsCount: itemsCount)
    }

    func auditReportsSingle(coinType: CoinType) -> Single<[Auditor]> {
        kit.auditReportsSingle(coinType: coinType)
    }

    func coinTypes(for category: String) -> [CoinType] {
        kit.coinTypes(forCategoryId: category)
    }

}

extension RateManager: IPostsManager {

    func posts(timestamp: TimeInterval) -> [CryptoNewsPost]? {
        kit.cryptoPosts(timestamp: timestamp)
    }

    var postsSingle: Single<[CryptoNewsPost]> {
        kit.cryptoPostsSingle
    }

}
