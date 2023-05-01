import Combine
import RxSwift
import RxRelay
import LanguageKit
import ThemeKit
import CurrencyKit
import PinKit
import WalletConnectV1
import ThemeKit

class MainSettingsService {
    private let disposeBag = DisposeBag()

    private let backupManager: BackupManager
    private let accountRestoreWarningManager: AccountRestoreWarningManager
    private let accountManager: AccountManager
    private let contactBookManager: ContactBookManager?
    private let pinKit: PinKit.Kit
    private let termsManager: TermsManager
    private let systemInfoManager: SystemInfoManager
    private let currencyKit: CurrencyKit.Kit
    private let appConfigProvider: AppConfigProvider
    private let walletConnectSessionManager: WalletConnectSessionManager
    private let walletConnectV2SessionManager: WalletConnectV2SessionManager

    private let iCloudAvailableErrorRelay = BehaviorRelay<Bool>(value: false)

    init(backupManager: BackupManager, accountRestoreWarningManager: AccountRestoreWarningManager, accountManager: AccountManager, contactBookManager: ContactBookManager?, pinKit: PinKit.Kit, termsManager: TermsManager,
         systemInfoManager: SystemInfoManager, currencyKit: CurrencyKit.Kit, appConfigProvider: AppConfigProvider,
         walletConnectSessionManager: WalletConnectSessionManager, walletConnectV2SessionManager: WalletConnectV2SessionManager) {
        self.backupManager = backupManager
        self.accountRestoreWarningManager = accountRestoreWarningManager
        self.accountManager = accountManager
        self.contactBookManager = contactBookManager
        self.pinKit = pinKit
        self.termsManager = termsManager
        self.systemInfoManager = systemInfoManager
        self.currencyKit = currencyKit
        self.appConfigProvider = appConfigProvider
        self.walletConnectSessionManager = walletConnectSessionManager
        self.walletConnectV2SessionManager = walletConnectV2SessionManager

        if let contactBookManager {
            subscribe(disposeBag, contactBookManager.iCloudErrorObservable) { [weak self] error in
                if error != nil, (self?.contactBookManager?.remoteSync ?? false) {
                    self?.iCloudAvailableErrorRelay.accept(true)
                } else {
                    self?.iCloudAvailableErrorRelay.accept(false)
                }
            }
        }
    }

}

extension MainSettingsService {

    var companyWebPageLink: String {
        appConfigProvider.companyWebPageLink
    }

    var noWalletRequiredActions: Bool {
        backupManager.allBackedUp && !accountRestoreWarningManager.hasNonStandard
    }

    var noWalletRequiredActionsObservable: Observable<Bool> {
        Observable.combineLatest(backupManager.allBackedUpObservable, accountRestoreWarningManager.hasNonStandardObservable) { allBackedUp, hasNonStandard in
            allBackedUp && !hasNonStandard
        }
    }

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    var isPinSetPublisher: AnyPublisher<Bool, Never> {
        pinKit.isPinSetPublisher
    }

    var isCloudAvailableError: Bool {
        (contactBookManager?.remoteSync ?? false) && (contactBookManager?.iCloudError != nil)
    }

    var iCloudAvailableErrorObservable: Observable<Bool> {
        iCloudAvailableErrorRelay.asObservable()
    }

    var termsAccepted: Bool {
        termsManager.termsAccepted
    }

    var termsAcceptedObservable: Observable<Bool> {
        termsManager.termsAcceptedObservable
    }

    var walletConnectSessionCount: Int {
        walletConnectSessionManager.sessions.count + walletConnectV2SessionManager.sessions.count
    }

    var walletConnectSessionCountObservable: Observable<Int> {
        Observable.combineLatest(walletConnectSessionManager.sessionsObservable, walletConnectV2SessionManager.sessionsObservable).map {
            $0.count + $1.count
        }
    }

    var walletConnectPendingRequestCount: Int {
        walletConnectV2SessionManager.activePendingRequests.count
    }

    var walletConnectPendingRequestCountObservable: Observable<Int> {
        walletConnectV2SessionManager.activePendingRequestsObservable.map { $0.count }
    }


    var currentLanguageDisplayName: String? {
        LanguageManager.shared.currentLanguageDisplayName
    }

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    var baseCurrencyPublisher: AnyPublisher<Currency, Never> {
        currencyKit.baseCurrencyUpdatedPublisher
    }

    var appVersion: String {
        systemInfoManager.appVersion.description
    }

    var activeAccount: Account? {
        accountManager.activeAccount
    }

}
