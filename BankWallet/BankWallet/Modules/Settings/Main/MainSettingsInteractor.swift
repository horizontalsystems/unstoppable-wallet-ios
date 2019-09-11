import RxSwift

class MainSettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: IMainSettingsInteractorDelegate?

    private let backupManager: IBackupManager
    private let languageManager: ILanguageManager
    private let themeManager: IThemeManager
    private let systemInfoManager: ISystemInfoManager
    private let currencyManager: ICurrencyManager
    private let appConfigProvider: IAppConfigProvider

    init(backupManager: IBackupManager, languageManager: ILanguageManager, themeManager: IThemeManager, systemInfoManager: ISystemInfoManager, currencyManager: ICurrencyManager, appConfigProvider: IAppConfigProvider) {
        self.backupManager = backupManager
        self.languageManager = languageManager
        self.themeManager = themeManager
        self.systemInfoManager = systemInfoManager
        self.currencyManager = currencyManager
        self.appConfigProvider = appConfigProvider

        backupManager.allBackedUpObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] allBackedUp in
                    self?.delegate?.didUpdate(allBackedUp: allBackedUp)
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

    var allBackedUp: Bool {
        return backupManager.allBackedUp
    }

    var currentLanguageDisplayName: String? {
        return languageManager.currentLanguageDisplayName
    }

    var baseCurrency: Currency {
        return currencyManager.baseCurrency
    }

    var lightMode: Bool {
        get {
            return themeManager.lightMode
        }
        set {
            themeManager.lightMode = newValue
        }
    }

    var appVersion: String {
        return systemInfoManager.appVersion
    }

}
