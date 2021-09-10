import RxSwift
import RxCocoa
import MarketKit

class CoinPriceAlertService {
    private let priceAlertManager: IPriceAlertManager
    private let localStorage: ILocalStorage
    private let disposeBag = DisposeBag()

    let coinType: CoinType
    let coinTitle: String

    private let priceAlertRelay = PublishRelay<PriceAlert?>()
    var priceAlert: PriceAlert? {
        didSet {
            priceAlertRelay.accept(priceAlert)
        }
    }

    init(priceAlertManager: IPriceAlertManager, localStorage: ILocalStorage, coinType: CoinType, coinTitle: String) {
        self.priceAlertManager = priceAlertManager
        self.localStorage = localStorage
        self.coinType = coinType
        self.coinTitle = coinTitle

        priceAlertManager.updateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in self?.sync(priceAlerts: $0) })
                .disposed(by: disposeBag)

        priceAlert = priceAlertManager.priceAlert(coinType: coinType, title: coinTitle)
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

    func priceAlert(platformCoin: PlatformCoin?) -> PriceAlert? {
        guard let platformCoin = platformCoin else {
            return nil
        }

        return priceAlertManager.priceAlert(coinType: platformCoin.coinType, title: platformCoin.name)
    }

    var priceAlertObservable: Observable<PriceAlert?> {
        priceAlertRelay.asObservable()
    }

}
