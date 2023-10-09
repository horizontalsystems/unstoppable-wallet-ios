import Combine
import RxRelay
import RxSwift

class AccountManager {
    private let passcodeManager: PasscodeManager
    private let storage: AccountCachedStorage
    private var cancellables = Set<AnyCancellable>()

    private let activeAccountRelay = PublishRelay<Account?>()
    private let accountsRelay = PublishRelay<[Account]>()
    private let accountUpdatedRelay = PublishRelay<Account>()
    private let accountDeletedRelay = PublishRelay<Account>()
    private let accountsLostRelay = BehaviorRelay<Bool>(value: false)

    private var lastCreatedAccount: Account?

    init(passcodeManager: PasscodeManager, accountStorage: AccountStorage, activeAccountStorage: ActiveAccountStorage) {
        self.passcodeManager = passcodeManager

        storage = AccountCachedStorage(level: passcodeManager.currentPasscodeLevel, accountStorage: accountStorage, activeAccountStorage: activeAccountStorage)

        passcodeManager.$currentPasscodeLevel
            .sink { [weak self] level in
                self?.handle(level: level)
            }
            .store(in: &cancellables)

        passcodeManager.$isDuressPasscodeSet
            .sink { [weak self] isSet in
                if !isSet {
                    self?.handleDisableDuress()
                }
            }
            .store(in: &cancellables)
    }

    private func handle(level: Int) {
        storage.set(level: level)

        accountsRelay.accept(storage.accounts)
        activeAccountRelay.accept(storage.activeAccount)
    }

    private func handleDisableDuress() {
        let currentLevel = passcodeManager.currentPasscodeLevel

        for account in storage.accounts {
            if account.level > currentLevel {
                account.level = currentLevel
                storage.save(account: account)
            }
        }

        accountsRelay.accept(storage.accounts)
    }

    private func clearAccounts(ids: [String]) {
        ids.forEach {
            storage.delete(accountId: $0)
        }

        if storage.allAccounts.isEmpty {
            accountsLostRelay.accept(true)
        }
    }

}

extension AccountManager {
    var activeAccountObservable: Observable<Account?> {
        activeAccountRelay.asObservable()
    }

    var accountsObservable: Observable<[Account]> {
        accountsRelay.asObservable()
    }

    var accountUpdatedObservable: Observable<Account> {
        accountUpdatedRelay.asObservable()
    }

    var accountDeletedObservable: Observable<Account> {
        accountDeletedRelay.asObservable()
    }

    var accountsLostObservable: Observable<Bool> {
        accountsLostRelay.asObservable()
    }

    var currentLevel: Int {
        passcodeManager.currentPasscodeLevel
    }

    var activeAccount: Account? {
        storage.activeAccount
    }

    func set(activeAccountId: String?) {
        guard storage.activeAccount?.id != activeAccountId else {
            return
        }

        storage.set(activeAccountId: activeAccountId)
        activeAccountRelay.accept(storage.activeAccount)
    }

    var accounts: [Account] {
        storage.accounts
    }

    func account(id: String) -> Account? {
        storage.account(id: id)
    }

    func update(account: Account) {
        storage.save(account: account)

        accountsRelay.accept(storage.accounts)
        accountUpdatedRelay.accept(account)
    }

    func save(account: Account) {
        storage.save(account: account)

        accountsRelay.accept(storage.accounts)

        set(activeAccountId: account.id)
    }

    func save(accounts: [Account]) {
        accounts.forEach { account in
            storage.save(account: account)
        }

        accountsRelay.accept(storage.accounts)
        if let first = accounts.first {
            set(activeAccountId: first.id)
        }
    }

    func delete(account: Account) {
        storage.delete(account: account)

        accountsRelay.accept(storage.accounts)
        accountDeletedRelay.accept(account)

        if account == storage.activeAccount {
            set(activeAccountId: storage.accounts.first?.id)
        }
    }

    func clear() {
        storage.clear()

        accountsRelay.accept(storage.accounts)

        set(activeAccountId: nil)
    }

    func handleLaunch() {
        let lostAccountIds = storage.lostAccountIds
        guard !lostAccountIds.isEmpty else {
            return
        }

        clearAccounts(ids: lostAccountIds)
    }

    func handleForeground() {
        let oldAccounts = storage.accounts

        let lostAccountIds = storage.lostAccountIds
        guard !lostAccountIds.isEmpty else {
            return
        }

        clearAccounts(ids: lostAccountIds)

        let lostAccounts = oldAccounts.filter { account in
            lostAccountIds.contains(account.id)
        }

        lostAccounts.forEach { account in
            accountDeletedRelay.accept(account)
        }

        accountsRelay.accept(storage.accounts)
    }

    func set(lastCreatedAccount: Account) {
        self.lastCreatedAccount = lastCreatedAccount
    }

    func popLastCreatedAccount() -> Account? {
        let account = lastCreatedAccount
        lastCreatedAccount = nil
        return account
    }

    func setDuress(accountIds: [String]) {
        let currentLevel = passcodeManager.currentPasscodeLevel

        for account in storage.accounts {
            if accountIds.contains(account.id) {
                account.level = currentLevel + 1
                storage.save(account: account)
            }
        }

        accountsRelay.accept(storage.accounts)
    }
}

class AccountCachedStorage {
    private let accountStorage: AccountStorage
    private let activeAccountStorage: ActiveAccountStorage

    private var _allAccounts: [String: Account]

    private var level: Int
    private var _accounts = [String: Account]()
    private var _activeAccount: Account?

    init(level: Int, accountStorage: AccountStorage, activeAccountStorage: ActiveAccountStorage) {
        self.level = level
        self.accountStorage = accountStorage
        self.activeAccountStorage = activeAccountStorage

        _allAccounts = accountStorage.allAccounts.reduce(into: [String: Account]()) { $0[$1.id] = $1 }

        syncAccounts()
    }

    private func syncAccounts() {
        _accounts = _allAccounts.filter { _, account in account.level >= level }
        _activeAccount = activeAccountStorage.activeAccountId(level: level).flatMap { _accounts[$0] } ?? _accounts.first?.value
    }

    var allAccounts: [Account] {
        Array(_allAccounts.values)
    }

    var accounts: [Account] {
        Array(_accounts.values)
    }

    var activeAccount: Account? {
        _activeAccount
    }

    var lostAccountIds: [String] {
        accountStorage.lostAccountIds
    }

    func set(level: Int) {
        self.level = level
        syncAccounts()
    }

    func account(id: String) -> Account? {
        _allAccounts[id]
    }

    func set(activeAccountId: String?) {
        activeAccountStorage.save(activeAccountId: activeAccountId, level: level)
        _activeAccount = activeAccountId.flatMap { _accounts[$0] }
    }

    func save(account: Account) {
        accountStorage.save(account: account)
        _allAccounts[account.id] = account

        if account.level >= level {
            _accounts[account.id] = account
        } else {
            _accounts.removeValue(forKey: account.id)
        }
    }

    func delete(account: Account) {
        accountStorage.delete(account: account)
        _allAccounts.removeValue(forKey: account.id)
        _accounts.removeValue(forKey: account.id)
    }

    func delete(accountId: String) {
        accountStorage.delete(accountId: accountId)
        _allAccounts.removeValue(forKey: accountId)
        _accounts.removeValue(forKey: accountId)
    }

    func clear() {
        accountStorage.clear()
        _allAccounts = [:]
        _accounts = [:]
    }
}
