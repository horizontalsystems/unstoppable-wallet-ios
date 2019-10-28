import RxSwift
import XRatesKit

class XRateManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let currencyManager: ICurrencyManager

    private let kit: XRatesKit

    init(walletManager: IWalletManager, currencyManager: ICurrencyManager) {
        self.walletManager = walletManager
        self.currencyManager = currencyManager

        kit = XRatesKit.instance(currencyCode: currencyManager.baseCurrency.code, minLogLevel: .verbose)

        walletManager.walletsUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] in
                    self?.onWalletsUpdated()
                })
                .disposed(by: disposeBag)

        currencyManager.baseCurrencyUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] in
                    self?.onBaseCurrencyUpdated()
                })
                .disposed(by: disposeBag)
    }

    private func onWalletsUpdated() {
        kit.set(coinCodes: walletManager.wallets.map { $0.coin.code })
    }

    private func onBaseCurrencyUpdated() {
        kit.set(currencyCode: currencyManager.baseCurrency.code)
    }

}

extension XRateManager: IXRateManager {

    func refresh() {
        kit.refresh()
    }

    func marketInfo(coinCode: String, currencyCode: String) -> MarketInfo? {
        kit.marketInfo(coinCode: coinCode, currencyCode: currencyCode)
    }

    func marketInfoObservable(coinCode: String, currencyCode: String) -> Observable<MarketInfo> {
        kit.marketInfoObservable(coinCode: coinCode, currencyCode: currencyCode)
    }

    func marketInfosObservable(currencyCode: String) -> Observable<[String: MarketInfo]> {
        kit.marketInfosObservable(currencyCode: currencyCode)
    }

    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        kit.historicalRate(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
    }

    func chartInfo(coinCode: String, currencyCode: String, chartType: ChartType) -> ChartInfo? {
        kit.chartInfo(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
    }

    func chartInfoObservable(coinCode: String, currencyCode: String, chartType: ChartType) -> Observable<ChartInfo> {
        kit.chartInfoObservable(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
    }

}
