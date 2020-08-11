import RxSwift
import CurrencyKit
import HsToolKit

class SendInteractor {
    weak var delegate: ISendInteractorDelegate?

    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit
    private let localStorage: ILocalStorage

    private let disposeBag = DisposeBag()

    init(reachabilityManager: IReachabilityManager, rateManager: IRateManager, currencyKit: ICurrencyKit, localStorage: ILocalStorage) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.localStorage = localStorage

        reachabilityManager.reachabilityObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] isReachable in
                    if isReachable {
                        self?.delegate?.sync()
                    }
                })
                .disposed(by: disposeBag)
    }

}

extension SendInteractor: ISendInteractor {

    var baseCurrency: Currency {
        currencyKit.baseCurrency
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

    func send(single: Single<Void>, logger: Logger) {
        single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] in
                    logger.debug("Send success", save: true)
                    self?.delegate?.didSend()
                }, onError: { [weak self] error in
                    logger.error("Send failed due to \(String(reflecting: error))", save: true)
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
