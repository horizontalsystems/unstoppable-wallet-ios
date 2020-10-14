import RxSwift
import CurrencyKit
import XRatesKit

class RateManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let rateCoinMapper: IRateCoinMapper
    private let feeCoinProvider: IFeeCoinProvider

    private let kit: XRatesKit

    init(walletManager: IWalletManager, currencyKit: ICurrencyKit, rateCoinMapper: IRateCoinMapper, feeCoinProvider: IFeeCoinProvider, coinMarketCapApiKey: String) {
        self.walletManager = walletManager
        self.rateCoinMapper = rateCoinMapper
        self.feeCoinProvider = feeCoinProvider

        kit = XRatesKit.instance(currencyCode: currencyKit.baseCurrency.code, coinMarketCapApiKey: coinMarketCapApiKey, indicatorPointCount: 50, marketInfoExpirationInterval: 10 * 60, topMarketsCount: 100)

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
        let allCoinCodes = wallets.reduce(into: [CoinCode]()) { result, wallet in
            result.append(wallet.coin.code)

            if let feeCoin = feeCoinProvider.feeCoin(coin: wallet.coin) {
                result.append(feeCoin.code)
            }
        }
        let convertedCoinCodes = allCoinCodes.compactMap { rateCoinMapper.convert(coinCode: $0) }
        let uniqueCoinCodes = Array(Set(convertedCoinCodes))

        kit.set(coinCodes: uniqueCoinCodes)
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
