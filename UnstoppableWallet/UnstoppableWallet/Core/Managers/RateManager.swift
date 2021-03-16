import RxSwift
import CurrencyKit
import XRatesKit
import CoinKit

class RateManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let rateCoinMapper: IRateCoinMapper
    private let feeCoinProvider: IFeeCoinProvider

    private let kit: XRatesKit

    init(walletManager: IWalletManager, currencyKit: ICurrencyKit, rateCoinMapper: IRateCoinMapper, feeCoinProvider: IFeeCoinProvider, coinMarketCapApiKey: String, cryptoCompareApiKey: String?, uniswapSubgraphUrl: String) {
        self.walletManager = walletManager
        self.rateCoinMapper = rateCoinMapper
        self.feeCoinProvider = feeCoinProvider

        kit = XRatesKit.instance(currencyCode: currencyKit.baseCurrency.code, coinMarketCapApiKey: coinMarketCapApiKey, cryptoCompareApiKey: cryptoCompareApiKey, uniswapSubgraphUrl: uniswapSubgraphUrl, indicatorPointCount: 50, marketInfoExpirationInterval: 10 * 60, topMarketsCount: 100, minLogLevel: .error)

        walletManager.walletsUpdatedObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] wallets in
                    self?.onUpdate(wallets: wallets)
                })
                .disposed(by: disposeBag)

        currencyKit.baseCurrencyUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] baseCurrency in
                    self?.onUpdate(baseCurrency: baseCurrency)
                })
                .disposed(by: disposeBag)
    }

    private func onUpdate(wallets: [Wallet]) {
        let allCoins = wallets.reduce(into: [Coin]()) { result, wallet in
            result.append(wallet.coin)

            if let feeCoin = feeCoinProvider.feeCoin(coin: wallet.coin) {
                result.append(feeCoin)
            }
        }
        let uniqueCoinTypes = Array(Set(allCoins.map { $0.type }))
        kit.set(coinTypes: uniqueCoinTypes)
    }

    private func onUpdate(baseCurrency: Currency) {
        kit.set(currencyCode: baseCurrency.code)
    }

}

extension RateManager: IRateManager {

    func refresh() {
        kit.refresh()
    }

    func marketInfo(coinType: CoinType, currencyCode: String) -> MarketInfo? {
        kit.marketInfo(coinType: coinType, currencyCode: currencyCode)
    }

    func globalMarketInfoSingle(currencyCode: String) -> Single<GlobalCoinMarket> {
        kit.globalMarketInfoSingle(currencyCode: currencyCode)
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

    func marketInfoObservable(coinType: CoinType, currencyCode: String) -> Observable<MarketInfo> {
        kit.marketInfoObservable(coinType: coinType, currencyCode: currencyCode)
    }

    func marketInfosObservable(currencyCode: String) -> Observable<[CoinType: MarketInfo]> {
        kit.marketInfosObservable(currencyCode: currencyCode) //todo: check!
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

}

extension RateManager: IPostsManager {

    func posts(timestamp: TimeInterval) -> [CryptoNewsPost]? {
        kit.cryptoPosts(timestamp: timestamp)
    }

    var postsSingle: Single<[CryptoNewsPost]> {
        kit.cryptoPostsSingle
    }

}
