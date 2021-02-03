import RxSwift
import CurrencyKit
import XRatesKit

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

    private func mapCoinForXRates(coins: [Coin]) -> [XRatesKit.Coin] {
        coins.compactMap { coin in
            let coinType = coin.type
            return rateCoinMapper.convert(coin: coin).map {
                XRatesKit.Coin(code: $0.code, title: $0.title, type: convertCoinTypeToXRateKitCoinType(coinType: coinType))
            }
        }
    }

    private func onUpdate(wallets: [Wallet]) {
        let allCoins = wallets.reduce(into: [Coin]()) { result, wallet in
            result.append(wallet.coin)

            if let feeCoin = feeCoinProvider.feeCoin(coin: wallet.coin) {
                result.append(feeCoin)
            }
        }
        let convertedCoinCodes = allCoins.compactMap { rateCoinMapper.convert(coin: $0) }
        let uniqueCoinCodes = Array(Set(convertedCoinCodes))


        kit.set(coins: mapCoinForXRates(coins: uniqueCoinCodes))
    }

    private func onUpdate(baseCurrency: Currency) {
        kit.set(currencyCode: baseCurrency.code)
    }

}

extension RateManager: IRateManager {

    func refresh() {
        kit.refresh()
    }

    func convertCoinTypeToXRateKitCoinType(coinType: CoinType) -> XRatesKit.CoinType {
        switch coinType {
        case .bitcoin: return .bitcoin
        case .litecoin: return .litecoin
        case .bitcoinCash: return .bitcoinCash
        case .dash: return .dash
        case .ethereum: return .ethereum
        case .erc20(let address): return .erc20(address: address)
        case .binance: return .binance
        case .zcash: return .zcash
        }
    }

    func convertXRateCoinTypeToCoinType(coinType: XRatesKit.CoinType) -> CoinType? {
        switch coinType {
        case .bitcoin: return .bitcoin
        case .litecoin: return .litecoin
        case .bitcoinCash: return .bitcoinCash
        case .dash: return .dash
        case .ethereum: return .ethereum
        case .erc20(let address): return .erc20(address: address)
        case .binance: return .binance(symbol: "")
        case .zcash: return .zcash
        case .eos: return nil
        }
    }

    func marketInfo(coinCode: String, currencyCode: String) -> MarketInfo? {
        guard let convertedCoinCode = rateCoinMapper.convert(coinCode: coinCode) else {
            return nil
        }

        return kit.marketInfo(coinCode: convertedCoinCode, currencyCode: currencyCode)
    }

    func globalMarketInfoSingle(currencyCode: String) -> Single<GlobalCoinMarket> {
        kit.globalMarketInfoSingle(currencyCode: currencyCode)
    }

    func topMarketsSingle(currencyCode: String, itemCount: Int) -> Single<[CoinMarket]> {
        kit.topMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: .hour24, itemsCount: itemCount)
    }

    func coinsMarketSingle(currencyCode: String, coinCodes: [String]) -> Single<[CoinMarket]> {
        kit.favorites(currencyCode: currencyCode, coinCodes: coinCodes)
    }

    func marketInfoObservable(coinCode: String, currencyCode: String) -> Observable<MarketInfo> {
        guard let convertedCoinCode = rateCoinMapper.convert(coinCode: coinCode) else {
            return Observable.error(RateError.disabledCoin)
        }

        return kit.marketInfoObservable(coinCode: convertedCoinCode, currencyCode: currencyCode)
    }

    func marketInfosObservable(currencyCode: String) -> Observable<[String: MarketInfo]> {
        kit.marketInfosObservable(currencyCode: currencyCode).map { [unowned self] marketInfos in
            var unconvertedMarketInfos = [String: MarketInfo]()

            for (coinCode, marketInfo) in marketInfos {
                for coinCode in self.rateCoinMapper.unconvert(coinCode: coinCode) {
                    unconvertedMarketInfos[coinCode] = marketInfo
                }
            }

            return unconvertedMarketInfos
        }
    }

    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        guard let convertedCoinCode = rateCoinMapper.convert(coinCode: coinCode) else {
            return Single.error(RateError.disabledCoin)
        }

        return kit.historicalRateSingle(coinCode: convertedCoinCode, currencyCode: currencyCode, timestamp: timestamp)
    }

    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Decimal? {
        guard let convertedCoinCode = rateCoinMapper.convert(coinCode: coinCode) else {
            return nil
        }

        return kit.historicalRate(coinCode: convertedCoinCode, currencyCode: currencyCode, timestamp: timestamp)
    }

    func chartInfo(coinCode: String, currencyCode: String, chartType: ChartType) -> ChartInfo? {
        guard let convertedCoinCode = rateCoinMapper.convert(coinCode: coinCode) else {
            return nil
        }

        return kit.chartInfo(coinCode: convertedCoinCode, currencyCode: currencyCode, chartType: chartType)
    }

    func chartInfoObservable(coinCode: String, currencyCode: String, chartType: ChartType) -> Observable<ChartInfo> {
        guard let convertedCoinCode = rateCoinMapper.convert(coinCode: coinCode) else {
            return Observable.error(RateError.disabledCoin)
        }

        return kit.chartInfoObservable(coinCode: convertedCoinCode, currencyCode: currencyCode, chartType: chartType)
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

extension RateManager {

    enum RateError: Error {
        case disabledCoin
    }

}
