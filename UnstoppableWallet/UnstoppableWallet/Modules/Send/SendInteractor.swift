import RxSwift
import CurrencyKit
import HsToolKit
import MarketKit

class SendInteractor {
    weak var delegate: ISendInteractorDelegate?

    private let rateManager: RateManagerNew
    private let currencyKit: CurrencyKit.Kit
    private let localStorage: ILocalStorage

    private let disposeBag = DisposeBag()

    init(reachabilityManager: IReachabilityManager, rateManager: RateManagerNew, currencyKit: CurrencyKit.Kit, localStorage: ILocalStorage) {
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

    func nonExpiredRateValue(coinType: CoinType, currencyCode: String) -> Decimal? {
        guard let latestRate = rateManager.latestRate(coinType: coinType, currencyCode: currencyCode), !latestRate.expired else {
            return nil
        }

        return latestRate.rate
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

    func subscribeToLatestRate(coinType: CoinType, currencyCode: String) {
        rateManager.latestRateObservable(coinType: coinType, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] latestRate in
                    self?.delegate?.didReceive(latestRate: latestRate)
                })
                .disposed(by: disposeBag)
    }

}
