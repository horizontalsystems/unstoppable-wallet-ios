import Combine
import Foundation
import RxSwift

class BackupPromptManager {
    private let repeatTimeInterval: TimeInterval = 24 * 60 * 60 // 24 hours

    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let cloudBackupManager: CloudBackupManager
    private let lockManager: LockManager
    private let localStorage: LocalStorage

    private let disposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private var isPresented = false
    private var isOnBalancePage = false

    init(accountManager: AccountManager, walletManager: WalletManager, adapterManager: AdapterManager, cloudBackupManager: CloudBackupManager, lockManager: LockManager, appManager: AppManager, localStorage: LocalStorage) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.cloudBackupManager = cloudBackupManager
        self.lockManager = lockManager
        self.localStorage = localStorage

        accountManager.activeAccountPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        accountManager.accountUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        lockManager.$isLocked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLocked in
                if !isLocked {
                    self?.showIfNeeded()
                }
            }
            .store(in: &cancellables)

        appManager.didBecomeActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showIfNeeded() }
            .store(in: &cancellables)

        adapterManager.adapterDataReadyPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.sync()
            }
            .store(in: &cancellables)

        sync()
    }

    private var targetAccount: Account? {
        guard let account = accountManager.activeAccount, account.canBeBackedUp, !account.watchAccount else {
            return nil
        }

        guard !(account.backedUp || cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())) else {
            return nil
        }

        return account
    }

    private func sync() {
        adaptersDisposeBag = DisposeBag()

        guard let account = targetAccount else {
            return
        }

        // adapters may still belong to the previous account right after a switch — skip until they catch up
        let adapterData = adapterManager.adapterData
        guard adapterData.account == account else {
            return
        }

        for adapter in adapterData.adapterMap.values {
            guard let adapter = adapter as? IBalanceAdapter else {
                continue
            }

            subscribe(adaptersDisposeBag, adapter.balanceDataUpdatedObservable) { [weak self] _ in
                DispatchQueue.main.async { self?.showIfNeeded() }
            }
        }

        showIfNeeded()
    }

    private func showIfNeeded() {
        guard !isPresented, isOnBalancePage, !lockManager.isLocked, let account = targetAccount else {
            return
        }

        if let lastShown = localStorage.backupPromptShownDates[account.id], Date().timeIntervalSince(lastShown) < repeatTimeInterval {
            return
        }

        // wallets/adapters update asynchronously after an account switch — never judge the new account by the old one's balances
        let walletData = walletManager.activeWalletData
        let adapterData = adapterManager.adapterData
        guard walletData.account == account, adapterData.account == account else {
            return
        }

        let hasBalance = walletData.wallets.contains { wallet in
            guard let adapter = adapterData.adapterMap[wallet] as? IBalanceAdapter else {
                return false
            }

            return adapter.balanceData.total > 0
        }

        guard hasBalance else {
            return
        }

        markShown(account: account)
        isPresented = true

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BackupPromptView(account: account, isPresented: isPresented)
        } onDismiss: { [weak self] in
            self?.isPresented = false
        }
    }

    private func markShown(account: Account) {
        // allAccounts, not accounts: the latter is passcode-level filtered and would drop
        // entries of accounts hidden by a duress passcode
        let accountIds = Set(accountManager.allAccounts.map(\.id))
        var dates = localStorage.backupPromptShownDates.filter { accountIds.contains($0.key) }
        dates[account.id] = Date()
        localStorage.backupPromptShownDates = dates
    }
}

extension BackupPromptManager {
    func onBalancePageAppear() {
        isOnBalancePage = true
        showIfNeeded()
    }

    func onBalancePageDisappear() {
        isOnBalancePage = false
    }
}
