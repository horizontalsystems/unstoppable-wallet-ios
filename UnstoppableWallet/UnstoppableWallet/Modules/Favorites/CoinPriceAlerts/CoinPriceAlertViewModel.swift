import RxSwift
import RxCocoa
import MarketKit

class CoinPriceAlertViewModel {
    private let service: CoinPriceAlertService
    private let disposeBag = DisposeBag()

    private let priceAlertActiveRelay = BehaviorRelay<Bool>(value: false)
    var priceAlertActive: Bool = false {
        didSet {
            priceAlertActiveRelay.accept(priceAlertActive)
        }
    }

    init(service: CoinPriceAlertService) {
        self.service = service

        subscribe(disposeBag, service.priceAlertObservable) { [weak self] in self?.sync(priceAlert: $0) }
        sync(priceAlert: service.priceAlert)
    }

    private func sync(priceAlert: PriceAlert?) {
        priceAlertActive = priceAlert?.changeState != .off || priceAlert?.trendState != .off ? true : false
    }

}

extension CoinPriceAlertViewModel {

    var alertNotificationEnabled: Bool {
        service.alertsOn
    }

    var priceAlertActiveDriver: Driver<Bool> {
        priceAlertActiveRelay.asDriver()
    }

    var coinType: CoinType {
        service.coinType
    }

}
