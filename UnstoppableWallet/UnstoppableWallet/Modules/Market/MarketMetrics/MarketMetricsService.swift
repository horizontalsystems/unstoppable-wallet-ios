import CurrencyKit
import XRatesKit
import RxSwift
import RxRelay

class MarketMetricsService {
    private let disposeBag = DisposeBag()
    private var marketMetricsDisposeBag = DisposeBag()

    private var timer: Timer?

    private let globalMarketInfoRelay = BehaviorRelay<DataStatus<GlobalCoinMarket>>(value: .loading)

    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit

    init(rateManager: IRateManager, appManager: IAppManager, currencyKit: ICurrencyKit) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit

        appManager.willEnterForegroundObservable
                .subscribe(onNext: { [weak self] in
                    self?.fetchMarketMetrics()
                })
                .disposed(by: disposeBag)

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] baseCurrency in self?.fetchMarketMetrics() }
        fetchMarketMetrics()
    }

    private func fetchMarketMetrics() {
        marketMetricsDisposeBag = DisposeBag()
        if globalMarketInfoRelay.value.data == nil {        // show loading only when cell hasn't data
            globalMarketInfoRelay.accept(.loading)
        }

        rateManager.globalMarketInfoSingle(currencyCode: currencyKit.baseCurrency.code, period: .hour24)
            .subscribe(onSuccess: { [weak self] info in
                self?.globalMarketInfoRelay.accept(.completed(info))
            }, onError: { [weak self] error in
                self?.globalMarketInfoRelay.accept(.failed(error))
            })
            .disposed(by: marketMetricsDisposeBag)
    }

}

extension MarketMetricsService {

    public var currency: Currency {
        currencyKit.baseCurrency
    }

    public var globalMarketInfoObservable: Observable<DataStatus<GlobalCoinMarket>> {
        globalMarketInfoRelay.asObservable()
    }

    public func refresh() {
        fetchMarketMetrics()
    }

}
