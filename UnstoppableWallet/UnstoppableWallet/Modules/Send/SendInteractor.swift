import RxSwift
import CurrencyKit
import HsToolKit
import MarketKit

class SendInteractor {
    weak var delegate: ISendInteractorDelegate?

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let localStorage: ILocalStorage

    private let disposeBag = DisposeBag()

    init(reachabilityManager: IReachabilityManager, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, localStorage: ILocalStorage) {
        self.marketKit = marketKit
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

    func nonExpiredRateValue(coinUid: String, currencyCode: String) -> Decimal? {
        guard let coinPrice = marketKit.coinPrice(coinUid: coinUid, currencyCode: currencyCode), !coinPrice.expired else {
            return nil
        }

        return coinPrice.value
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

    func subscribeToCoinPrice(coinUid: String, currencyCode: String) {
        marketKit.coinPriceObservable(coinUid: coinUid, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] coinPrice in
                    self?.delegate?.didReceive(coinPrice: coinPrice)
                })
                .disposed(by: disposeBag)
    }

}
