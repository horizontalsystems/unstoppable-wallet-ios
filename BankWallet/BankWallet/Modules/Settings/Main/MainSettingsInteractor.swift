import RxSwift

class MainSettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: IMainSettingsInteractorDelegate?

    private let localStorage: ILocalStorage
    private let backupManager: IBackupManager
    private let languageManager: ILanguageManager
    private let systemInfoManager: ISystemInfoManager
    private let currencyManager: ICurrencyManager

    init(localStorage: ILocalStorage, backupManager: IBackupManager, languageManager: ILanguageManager, systemInfoManager: ISystemInfoManager, currencyManager: ICurrencyManager, async: Bool = true) {
        self.localStorage = localStorage
        self.backupManager = backupManager
        self.languageManager = languageManager
        self.systemInfoManager = systemInfoManager
        self.currencyManager = currencyManager

        var nonBackedUpCountObservable = backupManager.nonBackedUpCountObservable
        var baseCurrencyUpdatedSignal: Observable<Void> = currencyManager.baseCurrencyUpdatedSignal

        if async {
            nonBackedUpCountObservable = nonBackedUpCountObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
            baseCurrencyUpdatedSignal = baseCurrencyUpdatedSignal
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
        }

        nonBackedUpCountObservable
                .subscribe(onNext: { [weak self] count in
                    self?.delegate?.didUpdateNonBackedUp(count: count)
                })
                .disposed(by: disposeBag)

        baseCurrencyUpdatedSignal
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didUpdateBaseCurrency()
                })
                .disposed(by: disposeBag)
    }

}

extension MainSettingsInteractor: IMainSettingsInteractor {

    var nonBackedUpCount: Int {
        return backupManager.nonBackedUpCount
    }

    var currentLanguage: String {
        return languageManager.displayNameForCurrentLanguage
    }

    var baseCurrency: String {
        return currencyManager.baseCurrency.code
    }

    var lightMode: Bool {
        return localStorage.lightMode
    }

    var appVersion: String {
        return systemInfoManager.appVersion
    }

    func set(lightMode: Bool) {
        localStorage.lightMode = lightMode
        delegate?.didUpdateLightMode()
    }

}
