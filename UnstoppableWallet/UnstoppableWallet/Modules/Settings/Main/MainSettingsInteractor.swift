import RxSwift
import LanguageKit
import ThemeKit
import CurrencyKit
import PinKit

class MainSettingsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: IMainSettingsInteractorDelegate?

    private let backupManager: IBackupManager
    private let pinKit: IPinKit
    private let termsManager: ITermsManager
    private let themeManager: ThemeManager
    private let systemInfoManager: ISystemInfoManager
    private let currencyKit: ICurrencyKit
    private let appConfigProvider: IAppConfigProvider

    init(backupManager: IBackupManager, pinKit: IPinKit, termsManager: ITermsManager, themeManager: ThemeManager,
         systemInfoManager: ISystemInfoManager, currencyKit: ICurrencyKit, appConfigProvider: IAppConfigProvider) {
        self.backupManager = backupManager
        self.pinKit = pinKit
        self.termsManager = termsManager
        self.themeManager = themeManager
        self.systemInfoManager = systemInfoManager
        self.currencyKit = currencyKit
        self.appConfigProvider = appConfigProvider

        backupManager.allBackedUpObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] allBackedUp in
                    self?.delegate?.didUpdate(allBackedUp: allBackedUp)
                })
                .disposed(by: disposeBag)

        pinKit.isPinSetObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] isPinSet in
                    self?.delegate?.didUpdate(pinSet: isPinSet)
                })
                .disposed(by: disposeBag)

        termsManager.termsAcceptedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] termsAccepted in
                    self?.delegate?.didUpdate(termsAccepted: termsAccepted)
                })
                .disposed(by: disposeBag)

        currencyKit.baseCurrencyUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.didUpdateBaseCurrency()
                })
                .disposed(by: disposeBag)
    }

}

extension MainSettingsInteractor: IMainSettingsInteractor {

    var companyWebPageLink: String {
        appConfigProvider.companyWebPageLink
    }

    var appWebPageLink: String {
        appConfigProvider.appWebPageLink
    }

    var allBackedUp: Bool {
        backupManager.allBackedUp
    }

    var pinSet: Bool {
        pinKit.isPinSet
    }

    var termsAccepted: Bool {
        termsManager.termsAccepted
    }

    var currentLanguageDisplayName: String? {
        LanguageManager.shared.currentLanguageDisplayName
    }

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    var lightMode: Bool {
        get {
            themeManager.lightMode
        }
        set {
            themeManager.lightMode = newValue
        }
    }

    var appVersion: String {
        systemInfoManager.appVersion
    }

}
