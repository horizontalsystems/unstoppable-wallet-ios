import RxSwift
import LanguageKit
import ThemeKit
import CurrencyKit
import PinKit
import WalletConnectV1
import ThemeKit

class MainSettingsService {
    private let backupManager: IBackupManager
    private let pinKit: IPinKit
    private let termsManager: ITermsManager
    private let themeManager: ThemeManager
    private let systemInfoManager: ISystemInfoManager
    private let currencyKit: CurrencyKit.Kit
    private let appConfigProvider: AppConfigProvider
    private let walletConnectSessionManager: WalletConnectSessionManager
    private let launchScreenManager: LaunchScreenManager

    init(backupManager: IBackupManager, pinKit: IPinKit, termsManager: ITermsManager, themeManager: ThemeManager,
         systemInfoManager: ISystemInfoManager, currencyKit: CurrencyKit.Kit, appConfigProvider: AppConfigProvider,
         walletConnectSessionManager: WalletConnectSessionManager, launchScreenManager: LaunchScreenManager) {
        self.backupManager = backupManager
        self.pinKit = pinKit
        self.termsManager = termsManager
        self.themeManager = themeManager
        self.systemInfoManager = systemInfoManager
        self.currencyKit = currencyKit
        self.appConfigProvider = appConfigProvider
        self.walletConnectSessionManager = walletConnectSessionManager
        self.launchScreenManager = launchScreenManager
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

    var launchScreen: LaunchScreen {
        launchScreenManager.launchScreen
    }

    var launchScreenObservable: Observable<LaunchScreen> {
        launchScreenManager.launchScreenObservable
    }

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    var baseCurrencyObservable: Observable<Currency> {
        currencyKit.baseCurrencyUpdatedObservable
    }

    var themeModeObservable: Observable<ThemeMode> {
        themeManager.changeThemeSignal.asObservable()
    }

    var themeMode: ThemeMode {
        themeManager.themeMode
    }

    var appVersion: String {
        systemInfoManager.appVersion.description
    }

}
