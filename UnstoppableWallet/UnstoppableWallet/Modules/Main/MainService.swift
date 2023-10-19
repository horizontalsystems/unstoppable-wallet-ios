import Foundation
import RxRelay
import RxSwift
import StorageKit

class MainService {
    private let keyTabIndex = "main-tab-index"

    private let localStorage: LocalStorage
    private let storage: StorageKit.ILocalStorage
    private let launchScreenManager: LaunchScreenManager
    private let accountManager: AccountManager
    private let passcodeManager: PasscodeManager
    private let lockManager: LockManager
    private let presetTab: MainModule.Tab?
    private let disposeBag = DisposeBag()

    private let hasAccountsRelay = PublishRelay<Bool>()
    private(set) var hasAccounts: Bool = false {
        didSet {
            if oldValue != hasAccounts {
                hasAccountsRelay.accept(hasAccounts)
            }
        }
    }

    private let hasWalletsRelay = PublishRelay<Bool>()
    private(set) var hasWallets: Bool = false {
        didSet {
            if oldValue != hasWallets {
                hasWalletsRelay.accept(hasWallets)
            }
        }
    }

    private let handleAlertsRelay = PublishRelay<Void>()
    private let showMarketRelay = PublishRelay<Bool>()

    private var isColdStart: Bool = true

    init(localStorage: LocalStorage, storage: StorageKit.ILocalStorage, launchScreenManager: LaunchScreenManager, accountManager: AccountManager, walletManager: WalletManager, appManager: IAppManager, passcodeManager: PasscodeManager, lockManager: LockManager, presetTab: MainModule.Tab?) {
        self.localStorage = localStorage
        self.storage = storage
        self.launchScreenManager = launchScreenManager
        self.accountManager = accountManager
        self.passcodeManager = passcodeManager
        self.lockManager = lockManager
        self.presetTab = presetTab

        subscribe(disposeBag, accountManager.accountsObservable) { [weak self] in self?.sync(accounts: $0) }
        subscribe(disposeBag, walletManager.activeWalletDataUpdatedObservable) { [weak self] in self?.sync(activeWallets: $0.wallets) }
        subscribe(disposeBag, launchScreenManager.showMarketObservable) { [weak self] in self?.sync(showMarket: $0) }
        subscribe(disposeBag, appManager.didBecomeActiveObservable) { [weak self] in self?.didBecomeActive() }

        sync(accounts: accountManager.accounts)
        sync(activeWallets: walletManager.activeWallets)
    }

    private func sync(accounts: [Account]) {
        hasAccounts = !accounts.isEmpty
    }

    private func sync(activeWallets: [Wallet]) {
        hasWallets = !activeWallets.isEmpty
    }

    private func sync(showMarket: Bool) {
        showMarketRelay.accept(showMarket)
    }

    private func didBecomeActive() {
        if !passcodeManager.isPasscodeSet, isColdStart { // If passcode not set, in first time we don't need to handleAlerts. (ViewController handle it from didAppear)
            isColdStart = false
            return
        }

        if !lockManager.isLocked { // If passcode locked, after input it ViewController will handle alerts form didAppear
            handleAlertsRelay.accept(())
        }
    }
}

extension MainService {
    var hasAccountsObservable: Observable<Bool> {
        hasAccountsRelay.asObservable()
    }

    var hasWalletsObservable: Observable<Bool> {
        hasWalletsRelay.asObservable()
    }

    var showMarket: Bool {
        launchScreenManager.showMarket
    }

    var handleAlertsObservable: Observable<Void> {
        handleAlertsRelay.asObservable()
    }

    var showMarketObservable: Observable<Bool> {
        showMarketRelay.asObservable()
    }

    var initialTab: MainModule.Tab {
        if let presetTab = presetTab {
            return presetTab
        }

        switch launchScreenManager.launchScreen {
        case .auto:
            if let storedIndex: Int = storage.value(for: keyTabIndex), let storedTab = MainModule.Tab(rawValue: storedIndex) {
                switch storedTab {
                case .settings: return .balance
                default: return storedTab
                }
            }

            return .balance
        case .balance:
            return .balance
        case .marketOverview, .watchlist:
            return .market
        }
    }

    func setMainShownOnce() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.localStorage.mainShownOnce = true
        }
    }

    func set(tab: MainModule.Tab) {
        storage.set(value: tab.rawValue, for: keyTabIndex)
    }

    var activeAccount: Account? {
        accountManager.activeAccount
    }
}
