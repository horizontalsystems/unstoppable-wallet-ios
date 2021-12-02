import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class CoinInvestorsService {
    private let coinUid: String
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<[CoinInvestment]>>()
    private(set) var state: DataStatus<[CoinInvestment]> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinUid: String, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.coinUid = coinUid
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        sync()
    }

    private func sync() {
        disposeBag = DisposeBag()

        state = .loading

        marketKit.investmentsSingle(coinUid: coinUid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] investments in
                    self?.state = .completed(investments)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension CoinInvestorsService {

    var stateObservable: Observable<DataStatus<[CoinInvestment]>> {
        stateRelay.asObservable()
    }

    var usdCurrency: Currency {
        let currencies = currencyKit.currencies
        return currencies.first { $0.code == "USD" } ?? currencies[0]
    }

    func refresh() {
        sync()
    }

}
