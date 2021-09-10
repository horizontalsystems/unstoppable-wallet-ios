import RxSwift
import MarketKit

class ChartNotificationInteractor {
    weak var delegate: IChartNotificationInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let priceAlertManager: IPriceAlertManager
    private let notificationManager: INotificationManager

    init(priceAlertManager: IPriceAlertManager, notificationManager: INotificationManager, appManager: IAppManager) {
        self.priceAlertManager = priceAlertManager
        self.notificationManager = notificationManager

        appManager.willEnterForegroundObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didEnterForeground()
                })
                .disposed(by: disposeBag)
    }

}

extension ChartNotificationInteractor: IChartNotificationInteractor {

    func priceAlert(coinType: CoinType, coinTitle: String) -> PriceAlert? {
        priceAlertManager.priceAlert(coinType: coinType, title: coinTitle)
    }

    func requestPermission() {
        notificationManager.requestPermission { [weak self] granted in
            if granted {
                self?.delegate?.didGrantPermission()
            } else {
                self?.delegate?.didDenyPermission()
            }
        }
    }

    func save(priceAlert: PriceAlert) {
        priceAlertManager.save(priceAlerts: [priceAlert])
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] error in
                    self?.delegate?.didFailSaveAlerts(error: error)
                })
                .disposed(by: disposeBag)
    }

}
