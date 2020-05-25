import RxSwift

class NotificationSettingsInteractor {
    weak var delegate: INotificationSettingsInteractorDelegate?

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

extension NotificationSettingsInteractor: INotificationSettingsInteractor {

    var alerts: [PriceAlert] {
        priceAlertManager.priceAlerts
    }

    var allowedBackgroundFetching: Bool {
        notificationManager.allowedBackgroundFetching
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

    func save(priceAlerts: [PriceAlert]) {
        priceAlertManager.save(priceAlerts: priceAlerts)
    }

}
