import Combine
import HsExtensions

class AccountManager {
    private let passcodeManager: PasscodeManager
    private let storage: AccountCachedStorage
    private var cancellables = Set<AnyCancellable>()

    private let activeAccountSubject = PassthroughSubject<Account?, Never>()
    private let accountsSubject = PassthroughSubject<[Account], Never>()
    private let accountUpdatedSubject = PassthroughSubject<Account, Never>()
    private let accountDeletedSubject = PassthroughSubject<Account, Never>()

    private var lastCreatedAccount: Account?

    @PostPublished var accountsLost = false

    init(passcodeManager: PasscodeManager, accountStorage: AccountStorage, activeAccountStorage: ActiveAccountStorage) {
        self.passcodeManager = passcodeManager

        storage = AccountCachedStorage(level: passcodeManager.currentPasscodeLevel, accountStorage: accountStorage, activeAccountStorage: activeAccountStorage)

        passcodeManager.$currentPasscodeLevel
            .sink { [weak self] in self?.handle(level: $0) }
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

        accountsSubject.send(storage.accounts)
        activeAccountSubject.send(storage.activeAccount)
    }

    private func handleDisableDuress() {
        let currentLevel = passcodeManager.currentPasscodeLevel

        for account in storage.accounts {
            if account.level > currentLevel {
                account.level = currentLevel
                storage.save(account: account)
            }
        }

        accountsSubject.send(storage.accounts)
    }

    private func clearAccounts(ids: [String]) {
        for id in ids {
            storage.delete(accountId: id)
        }

        if storage.allAccounts.isEmpty {
            accountsLost = true
        }
    }
}

extension AccountManager {
    var activeAccountPublisher: AnyPublisher<Account?, Never> {
        activeAccountSubject.eraseToAnyPublisher()
    }

    var accountsPublisher: AnyPublisher<[Account], Never> {
        accountsSubject.eraseToAnyPublisher()
    }

    var accountUpdatedPublisher: AnyPublisher<Account, Never> {
        accountUpdatedSubject.eraseToAnyPublisher()
    }

    var accountDeletedPublisher: AnyPublisher<Account, Never> {
        accountDeletedSubject.eraseToAnyPublisher()
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
        activeAccountSubject.send(storage.activeAccount)
    }

    var accounts: [Account] {
        storage.accounts
    }

    func account(id: String) -> Account? {
        storage.account(id: id)
    }

    func update(account: Account) {
        storage.save(account: account)

        accountsSubject.send(storage.accounts)
        accountUpdatedSubject.send(account)
    }

    func save(account: Account) {
        storage.save(account: account)

        accountsSubject.send(storage.accounts)

        set(activeAccountId: account.id)
    }

    func save(accounts: [Account]) {
        for account in accounts {
            storage.save(account: account)
        }

        accountsSubject.send(storage.accounts)
        if let first = accounts.first {
            set(activeAccountId: first.id)
        }
    }

    func delete(account: Account) {
        storage.delete(account: account)

        accountsSubject.send(storage.accounts)
        accountDeletedSubject.send(account)

        if account == storage.activeAccount {
            set(activeAccountId: storage.accounts.first?.id)
        }
    }

    func clear() {
        storage.clear()

        accountsSubject.send(storage.accounts)

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

        for account in lostAccounts {
            accountDeletedSubject.send(account)
        }

        accountsSubject.send(storage.accounts)
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

        accountsSubject.send(storage.accounts)
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
