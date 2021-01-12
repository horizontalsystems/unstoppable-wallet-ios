import CurrencyKit
import XRatesKit
import RxSwift
import RxRelay

class MarketMetricsService {
    private let disposeBag = DisposeBag()
    private var timer: Timer?

    private let globalMarketInfoRelay = BehaviorRelay<DataStatus<GlobalMarketInfo>>(value: .loading)

    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit

    init(rateManager: IRateManager, currencyKit: ICurrencyKit) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit

        fetchMarketMetrics()
    }

    private func fetchMarketMetrics() {
        globalMarketInfoRelay.accept(.loading)

        rateManager.globalMarketInfoSingle(currencyCode: currencyKit.baseCurrency.code)
            .subscribe(onSuccess: { [weak self] info in
                self?.globalMarketInfoRelay.accept(.completed(info))
            }, onError: { [weak self] error in
                self?.globalMarketInfoRelay.accept(.failed(error))
            }).disposed(by: disposeBag)
    }

}

extension MarketMetricsService {

    public var currency: Currency {
        currencyKit.baseCurrency
    }

    public var globalMarketInfoObservable: Observable<DataStatus<GlobalMarketInfo>> {
        globalMarketInfoRelay.asObservable()
    }

    public func refresh() {
        fetchMarketMetrics()
    }

}
