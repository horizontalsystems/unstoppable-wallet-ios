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
    private let cloudAccountBackupManager: CloudBackupManager
    private let accountRestoreWarningManager: AccountRestoreWarningManager
    private let accountManager: AccountManager
    private let contactBookManager: ContactBookManager
    private let pinKit: PinKit.Kit
    private let termsManager: TermsManager
    private let systemInfoManager: SystemInfoManager
    private let currencyKit: CurrencyKit.Kit
    private let walletConnectSessionManager: WalletConnectSessionManager
    private let subscriptionManager: SubscriptionManager

    private let iCloudAvailableErrorRelay = BehaviorRelay<Bool>(value: false)
    private let noWalletRequiredActionsRelay = BehaviorRelay<Bool>(value: false)

    init(backupManager: BackupManager, cloudAccountBackupManager: CloudBackupManager, accountRestoreWarningManager: AccountRestoreWarningManager, accountManager: AccountManager, contactBookManager: ContactBookManager, pinKit: PinKit.Kit, termsManager: TermsManager,
         systemInfoManager: SystemInfoManager, currencyKit: CurrencyKit.Kit, walletConnectSessionManager: WalletConnectSessionManager, subscriptionManager: SubscriptionManager) {
        self.cloudAccountBackupManager = cloudAccountBackupManager
        self.backupManager = backupManager
        self.accountRestoreWarningManager = accountRestoreWarningManager
        self.accountManager = accountManager
        self.contactBookManager = contactBookManager
        self.pinKit = pinKit
        self.termsManager = termsManager
        self.systemInfoManager = systemInfoManager
        self.currencyKit = currencyKit
        self.walletConnectSessionManager = walletConnectSessionManager
        self.subscriptionManager = subscriptionManager

        subscribe(disposeBag, contactBookManager.iCloudErrorObservable) { [weak self] error in
            if error != nil, (self?.contactBookManager.remoteSync ?? false) {
                self?.iCloudAvailableErrorRelay.accept(true)
            } else {
                self?.iCloudAvailableErrorRelay.accept(false)
            }
        }

        subscribe(disposeBag, backupManager.allBackedUpObservable) { [weak self] _ in self?.syncWalletRequiredActions() }
        subscribe(disposeBag, accountRestoreWarningManager.hasNonStandardObservable) { [weak self] _ in self?.syncWalletRequiredActions() }

        syncWalletRequiredActions()
    }

    private func syncWalletRequiredActions() {
        noWalletRequiredActionsRelay.accept(backupManager.allBackedUp && !accountRestoreWarningManager.hasNonStandard)
    }

}

extension MainSettingsService {

    var noWalletRequiredActions: Bool {
        backupManager.allBackedUp && !accountRestoreWarningManager.hasNonStandard
    }

    var noWalletRequiredActionsObservable: Observable<Bool> {
        noWalletRequiredActionsRelay.asObservable()
    }

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    var isPinSetPublisher: AnyPublisher<Bool, Never> {
        pinKit.isPinSetPublisher
    }

    var isCloudAvailableError: Bool {
        contactBookManager.remoteSync && contactBookManager.iCloudError != nil
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
        walletConnectSessionManager.sessions.count
    }

    var walletConnectSessionCountObservable: Observable<Int> {
        walletConnectSessionManager.sessionsObservable.map { $0.count }
    }

    var walletConnectPendingRequestCount: Int {
        walletConnectSessionManager.activePendingRequests.count
    }

    var walletConnectPendingRequestCountObservable: Observable<Int> {
        walletConnectSessionManager.activePendingRequestsObservable.map { $0.count }
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

    var isAuthenticated: Bool {
        subscriptionManager.isAuthenticated
    }

    var walletConnectState: WalletConnectState {
        guard let activeAccount = activeAccount else {
            return .noAccount
        }

        if !activeAccount.type.supportsWalletConnect {
            return .nonSupportedAccountType(accountType: activeAccount.type)
        }

        if activeAccount.backedUp || cloudAccountBackupManager.backedUp(uniqueId: activeAccount.type.uniqueId()) {
            return .backedUp
        }
        return .unBackedUpAccount(account: activeAccount)
    }

    var analyticsLink: String {
        AppConfig.analyticsLink
    }

}

extension MainSettingsService {

    enum WalletConnectState {
        case noAccount
        case backedUp
        case nonSupportedAccountType(accountType: AccountType)
        case unBackedUpAccount(account: Account)
    }

}
