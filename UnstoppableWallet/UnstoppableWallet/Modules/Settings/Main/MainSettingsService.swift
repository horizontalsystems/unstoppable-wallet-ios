import RxSwift
import LanguageKit
import ThemeKit
import CurrencyKit
import PinKit
import WalletConnect

class MainSettingsService {
    private let backupManager: IBackupManager
    private let pinKit: IPinKit
    private let termsManager: ITermsManager
    private let themeManager: ThemeManager
    private let systemInfoManager: ISystemInfoManager
    private let currencyKit: ICurrencyKit
    private let appConfigProvider: IAppConfigProvider
    private let walletConnectSessionManager: WalletConnectSessionManager

    init(backupManager: IBackupManager, pinKit: IPinKit, termsManager: ITermsManager, themeManager: ThemeManager,
         systemInfoManager: ISystemInfoManager, currencyKit: ICurrencyKit, appConfigProvider: IAppConfigProvider,
         walletConnectSessionManager: WalletConnectSessionManager) {
        self.backupManager = backupManager
        self.pinKit = pinKit
        self.termsManager = termsManager
        self.themeManager = themeManager
        self.systemInfoManager = systemInfoManager
        self.currencyKit = currencyKit
        self.appConfigProvider = appConfigProvider
        self.walletConnectSessionManager = walletConnectSessionManager
    }

}

extension MainSettingsService {

    var companyWebPageLink: String {
        appConfigProvider.companyWebPageLink
    }

    var allBackedUp: Bool {
        backupManager.allBackedUp
    }

    var allBackedUpObservable: Observable<Bool> {
        backupManager.allBackedUpObservable
    }

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    var isPinSetObservable: Observable<Bool> {
        pinKit.isPinSetObservable
    }

    var termsAccepted: Bool {
        termsManager.termsAccepted
    }

    var termsAcceptedObservable: Observable<Bool> {
        termsManager.termsAcceptedObservable
    }

    var walletConnectSessionCount: Int {
        walletConnectSessionManager.sessions.count
    }

    var walletConnectSessionCountObservable: Observable<Int> {
        walletConnectSessionManager.sessionsObservable.map { $0.count }
    }

    var currentLanguageDisplayName: String? {
        LanguageManager.shared.currentLanguageDisplayName
    }

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    var baseCurrencyObservable: Observable<Currency> {
        currencyKit.baseCurrencyUpdatedObservable
    }

    var lightMode: Bool {
        get {
            themeManager.lightMode
        }
        set {
            themeManager.lightMode = newValue
        }
    }

    var telegramAccount: String {
        appConfigProvider.telegramAccount
    }

    var twitterAccount: String {
        appConfigProvider.twitterAccount
    }

    var redditAccount: String {
        appConfigProvider.redditAccount
    }

    var appVersion: String {
        systemInfoManager.appVersion
    }

}
