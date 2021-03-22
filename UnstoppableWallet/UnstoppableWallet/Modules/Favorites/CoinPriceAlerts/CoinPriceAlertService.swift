import RxSwift
import RxCocoa
import CoinKit

class CoinPriceAlertService {
    private let priceAlertManager: IPriceAlertManager
    private let localStorage: ILocalStorage
    private let disposeBag = DisposeBag()

    let coinType: CoinType

    private let priceAlertRelay = PublishRelay<PriceAlert?>()
    var priceAlert: PriceAlert? {
        didSet {
            priceAlertRelay.accept(priceAlert)
        }
    }

    init(priceAlertManager: IPriceAlertManager, localStorage: ILocalStorage, coinType: CoinType) {
        self.priceAlertManager = priceAlertManager
        self.localStorage = localStorage
        self.coinType = coinType

        priceAlertManager.updateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in self?.sync(priceAlerts: $0) })
                .disposed(by: disposeBag)

        sync(priceAlerts: [priceAlertManager.priceAlert(coinType: coinType)].compactMap { $0 })
    }

    private func sync(priceAlerts: [PriceAlert]) {
        priceAlert = priceAlerts.first {
            $0.coinType == coinType
        }
    }

}

extension CoinPriceAlertService {

    var alertsOn: Bool {
        localStorage.pushNotificationsOn
    }

    var alertNotificationAllowed: Bool {
        priceAlertManager.alertNotificationAllowed(coinType: coinType)
    }

    func priceAlert(coin: Coin?) -> PriceAlert? {
        guard let coin = coin else {
            return nil
        }

        return priceAlertManager.priceAlert(coinType: coin.type)
    }


    var priceAlertObservable: Observable<PriceAlert?> {
        priceAlertRelay.asObservable()
    }

}
