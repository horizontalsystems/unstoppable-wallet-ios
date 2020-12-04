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

    private func onUpdate(wallets: [Wallet]) {
        let allCoins = wallets.reduce(into: [Coin]()) { result, wallet in
            result.append(wallet.coin)

            if let feeCoin = feeCoinProvider.feeCoin(coin: wallet.coin) {
                result.append(feeCoin)
            }
        }
        let convertedCoinCodes = allCoins.compactMap { rateCoinMapper.convert(coin: $0) }
        let uniqueCoinCodes = Array(Set(convertedCoinCodes))
        
        let kitCoins = uniqueCoinCodes.map { coin -> XRatesKit.Coin in
            switch coin.type {
                case .binance: return XRatesKit.Coin(code: coin.code, title: coin.title, type: .binance)
                case .bitcoin: return XRatesKit.Coin(code: coin.code, title: coin.title, type: .bitcoin)
                case .bitcoinCash: return XRatesKit.Coin(code: coin.code, title: coin.title, type: .bitcoinCash)
                case .dash: return XRatesKit.Coin(code: coin.code, title: coin.title, type: .dash)
                case .eos: return XRatesKit.Coin(code: coin.code, title: coin.title, type: .eos)
                case .erc20(let address, _, _, _): return XRatesKit.Coin(code: coin.code, title: coin.title, type: .erc20(address: address))
                case .ethereum: return XRatesKit.Coin(code: coin.code, title: coin.title, type: .ethereum)
                case .litecoin: return XRatesKit.Coin(code: coin.code, title: coin.title, type: .litecoin)
                case .zcash: return XRatesKit.Coin(code: coin.code, title: coin.title, type: .zcash)
            }
        }

        kit.set(coins: kitCoins)
    }

    private func onUpdate(baseCurrency: Currency) {
        kit.set(currencyCode: baseCurrency.code)
    }

}

extension RateManager: IRateManager {

    func refresh() {
        kit.refresh()
    }

    func marketInfo(coinCode: String, currencyCode: String) -> MarketInfo? {
        guard let convertedCoinCode = rateCoinMapper.convert(coinCode: coinCode) else {
            return nil
        }

        return kit.marketInfo(coinCode: convertedCoinCode, currencyCode: currencyCode)
    }

    func topMarketInfos(currencyCode: String) -> Single<[TopMarket]> {
        kit.topMarketInfos(currencyCode: currencyCode)
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
