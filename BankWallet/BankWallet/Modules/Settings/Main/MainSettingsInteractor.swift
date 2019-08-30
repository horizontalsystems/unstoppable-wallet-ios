import RxSwift

class MainSettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: IMainSettingsInteractorDelegate?

    private let localStorage: ILocalStorage
    private let backupManager: IBackupManager
    private let languageManager: ILanguageManager
    private let systemInfoManager: ISystemInfoManager
    private let currencyManager: ICurrencyManager
    private let appConfigProvider: IAppConfigProvider

    init(localStorage: ILocalStorage, backupManager: IBackupManager, languageManager: ILanguageManager, systemInfoManager: ISystemInfoManager, currencyManager: ICurrencyManager, appConfigProvider: IAppConfigProvider) {
        self.localStorage = localStorage
        self.backupManager = backupManager
        self.languageManager = languageManager
        self.systemInfoManager = systemInfoManager
        self.currencyManager = currencyManager
        self.appConfigProvider = appConfigProvider

        backupManager.nonBackedUpCountObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] count in
                    self?.delegate?.didUpdateNonBackedUp(count: count)
                })
                .disposed(by: disposeBag)

        currencyManager.baseCurrencyUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didUpdateBaseCurrency()
                })
                .disposed(by: disposeBag)
    }

}

extension MainSettingsInteractor: IMainSettingsInteractor {

    var companyWebPageLink: String {
        return appConfigProvider.companyWebPageLink
    }

    var appWebPageLink: String {
        return appConfigProvider.appWebPageLink
    }

    var nonBackedUpCount: Int {
        return backupManager.nonBackedUpCount
    }

    var currentLanguageDisplayName: String {
        return languageManager.displayNameForCurrentLanguage
    }

    var baseCurrency: Currency {
        return currencyManager.baseCurrency
    }

    var lightMode: Bool {
        get {
            return localStorage.lightMode
        }
        set {
            localStorage.lightMode = newValue
        }
    }

    var appVersion: String {
        return systemInfoManager.appVersion
    }

}
