import RxSwift

class MainSettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: IMainSettingsInteractorDelegate?

    private let localStorage: ILocalStorage
    private let wordsManager: IWordsManager
    private let languageManager: ILanguageManager
    private let systemInfoManager: ISystemInfoManager
    private let currencyManager: ICurrencyManager

    init(localStorage: ILocalStorage, wordsManager: IWordsManager, languageManager: ILanguageManager, systemInfoManager: ISystemInfoManager, currencyManager: ICurrencyManager) {
        self.localStorage = localStorage
        self.wordsManager = wordsManager
        self.languageManager = languageManager
        self.systemInfoManager = systemInfoManager
        self.currencyManager = currencyManager

        wordsManager.backedUpSubject
                .subscribe(onNext: { [weak self] isBackedUp in
                    self?.onUpdate(isBackedUp: isBackedUp)
                })
                .disposed(by: disposeBag)

        currencyManager.baseCurrencyUpdatedSignal
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didUpdateBaseCurrency()
                })
                .disposed(by: disposeBag)
    }

    private func onUpdate(isBackedUp: Bool) {
        if isBackedUp {
            delegate?.didBackup()
        }
    }

}

extension MainSettingsInteractor: IMainSettingsInteractor {

    var isBackedUp: Bool {
        return wordsManager.isBackedUp
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
