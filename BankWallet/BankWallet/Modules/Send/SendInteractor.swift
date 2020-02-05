import RxSwift

class SendInteractor {
    weak var delegate: ISendInteractorDelegate?

    private let rateManager: IRateManager
    private let currencyManager: ICurrencyManager
    private let localStorage: ILocalStorage

    private let disposeBag = DisposeBag()

    init(reachabilityManager: IReachabilityManager, rateManager: IRateManager, currencyManager: ICurrencyManager, localStorage: ILocalStorage) {
        self.rateManager = rateManager
        self.currencyManager = currencyManager
        self.localStorage = localStorage

        reachabilityManager.reachabilitySignal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    if reachabilityManager.isReachable {
                        self?.delegate?.sync()
                    }
                })
                .disposed(by: disposeBag)
    }

}

extension SendInteractor: ISendInteractor {

    var baseCurrency: Currency {
        currencyManager.baseCurrency
    }

    var defaultInputType: SendInputType {
        localStorage.sendInputType ?? .coin
    }

    func nonExpiredRateValue(coinCode: CoinCode, currencyCode: String) -> Decimal? {
        guard let marketInfo = rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode), !marketInfo.expired else {
            return nil
        }
        return marketInfo.rate
    }

    func send(single: Single<Void>) {
        single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] in
                    self?.delegate?.didSend()
                }, onError: { [weak self] error in
                    self?.delegate?.didFailToSend(error: error)
                })
                .disposed(by: disposeBag)
    }

    func subscribeToMarketInfo(coinCode: CoinCode, currencyCode: String) {
        rateManager.marketInfoObservable(coinCode: coinCode, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] marketInfo in
                    self?.delegate?.didReceive(marketInfo: marketInfo)
                })
                .disposed(by: disposeBag)
    }

}
