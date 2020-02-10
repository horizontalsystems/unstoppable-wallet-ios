import RxSwift
import CurrencyKit
import XRatesKit

class RateManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let currencyKit: ICurrencyKit
    private let rateCoinMapper: IRateCoinMapper

    private let kit: XRatesKit

    init(walletManager: IWalletManager, currencyKit: ICurrencyKit, rateCoinMapper: IRateCoinMapper) {
        self.walletManager = walletManager
        self.currencyKit = currencyKit
        self.rateCoinMapper = rateCoinMapper

        kit = XRatesKit.instance(currencyCode: currencyKit.baseCurrency.code, marketInfoExpirationInterval: 10 * 60)

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

        initMapper()
    }

    private func initMapper() {
        rateCoinMapper.addCoin(direction: .convert, from: "HOT", to: "HOLO")
        rateCoinMapper.addCoin(direction: .unconvert, from: "HOLO", to: "HOT")

        rateCoinMapper.addCoin(direction: .convert, from: "PGL", to: nil)
        rateCoinMapper.addCoin(direction: .convert, from: "PPT", to: nil)
        rateCoinMapper.addCoin(direction: .convert, from: "EOSDT", to: nil)
        rateCoinMapper.addCoin(direction: .unconvert, from: "PGL", to: nil)
        rateCoinMapper.addCoin(direction: .unconvert, from: "PPT", to: nil)
        rateCoinMapper.addCoin(direction: .unconvert, from: "EOSDT", to: nil)
    }

    private func onUpdate(wallets: [Wallet]) {
        kit.set(coinCodes: wallets.map { converted(coinCode: $0.coin.code) })
    }

    private func onUpdate(baseCurrency: Currency) {
        kit.set(currencyCode: baseCurrency.code)
    }

    private func converted(coinCode: String) -> String {
        rateCoinMapper.convertCoinMap[coinCode] ?? coinCode
    }

    private func unconverted(coinCode: String) -> String {
        rateCoinMapper.unconvertCoinMap[coinCode] ?? coinCode
    }

}

extension RateManager: IRateManager {

    func refresh() {
        kit.refresh()
    }

    func marketInfo(coinCode: String, currencyCode: String) -> MarketInfo? {
        kit.marketInfo(coinCode: converted(coinCode: coinCode), currencyCode: currencyCode)
    }

    func marketInfoObservable(coinCode: String, currencyCode: String) -> Observable<MarketInfo> {
        kit.marketInfoObservable(coinCode: converted(coinCode: coinCode), currencyCode: currencyCode)
    }

    func marketInfosObservable(currencyCode: String) -> Observable<[String: MarketInfo]> {
        kit.marketInfosObservable(currencyCode: currencyCode).map { [unowned self] marketInfos in
            var unconvertedMarketInfos = [String: MarketInfo]()

            for (coinCode, marketInfo) in marketInfos {
                unconvertedMarketInfos[self.unconverted(coinCode: coinCode)] = marketInfo
            }

            return unconvertedMarketInfos
        }
    }

    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        kit.historicalRateSingle(coinCode: converted(coinCode: coinCode), currencyCode: currencyCode, timestamp: timestamp)
    }

    func chartInfo(coinCode: String, currencyCode: String, chartType: ChartType) -> ChartInfo? {
        kit.chartInfo(coinCode: converted(coinCode: coinCode), currencyCode: currencyCode, chartType: chartType)
    }

    func chartInfoObservable(coinCode: String, currencyCode: String, chartType: ChartType) -> Observable<ChartInfo> {
        kit.chartInfoObservable(coinCode: converted(coinCode: coinCode), currencyCode: currencyCode, chartType: chartType)
    }

}
