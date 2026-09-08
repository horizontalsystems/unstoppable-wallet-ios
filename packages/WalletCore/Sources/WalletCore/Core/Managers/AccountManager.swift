import Combine
import HsExtensions

public class AccountManager {
    private let passcodeManager: PasscodeManager
    private let storage: AccountCachedStorage
    private var cancellables = Set<AnyCancellable>()

    private let activeAccountSubject = PassthroughSubject<Account?, Never>()
    private let accountsSubject = PassthroughSubject<[Account], Never>()
    private let accountUpdatedSubject = PassthroughSubject<Account, Never>()
    private let accountDeletedSubject = PassthroughSubject<Account, Never>()

    private(set) var lastCreatedAccount: Account?

    @PostPublished var lostAccountRecords: [AccountRecord]?

    public init(passcodeManager: PasscodeManager, accountStorage: AccountStorage, activeAccountStorage: ActiveAccountStorage) {
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
        if lostAccountRecords != nil {
            handleLaunch()
        }
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
}

extension AccountManager {
    public var activeAccountPublisher: AnyPublisher<Account?, Never> {
        activeAccountSubject.eraseToAnyPublisher()
    }

    public var accountsPublisher: AnyPublisher<[Account], Never> {
        accountsSubject.eraseToAnyPublisher()
    }

    var accountUpdatedPublisher: AnyPublisher<Account, Never> {
        accountUpdatedSubject.eraseToAnyPublisher()
    }

    public var accountDeletedPublisher: AnyPublisher<Account, Never> {
        accountDeletedSubject.eraseToAnyPublisher()
    }

    var currentLevel: Int {
        passcodeManager.currentPasscodeLevel
    }

    public var activeAccount: Account? {
        storage.activeAccount
    }

    public func set(activeAccountId: String?) {
        guard storage.activeAccount?.id != activeAccountId else {
            return
        }

        storage.set(activeAccountId: activeAccountId)
        activeAccountSubject.send(storage.activeAccount)
    }

    public var allAccounts: [Account] {
        storage.allAccounts
    }

    public var accounts: [Account] {
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

    public func delete(account: Account) {
        storage.delete(account: account)

        accountsSubject.send(storage.accounts)
        accountDeletedSubject.send(account)

        if account == storage.activeAccount {
            set(activeAccountId: storage.accounts.first?.id)
        }
    }

    func removeLostAccounts(ids: Set<String>) throws {
        try storage.removeLostAccounts(ids: ids)
        handleLaunch()
    }

    func clear() {
        storage.clear()
        lostAccountRecords = nil

        accountsSubject.send(storage.accounts)

        set(activeAccountId: nil)
    }

    func handleLaunch() {
        let records = storage.lostAccountRecords
        lostAccountRecords = records.isEmpty ? nil : records
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

protocol IAccountStorage {
    var allAccounts: ([Account], [AccountRecord]) { get }
    func save(account: Account)
    func delete(account: Account)
    func delete(accountIds: Set<String>) throws
    func clear()
}

class AccountCachedStorage {
    private let accountStorage: IAccountStorage
    private let activeAccountStorage: ActiveAccountStorage

    private var _allAccounts: [String: Account]
    private var _lostAccountRecords: [AccountRecord]

    private var level: Int
    private var _accounts = [String: Account]()
    private var _activeAccount: Account?

    init(level: Int, accountStorage: IAccountStorage, activeAccountStorage: ActiveAccountStorage) {
        self.level = level
        self.accountStorage = accountStorage
        self.activeAccountStorage = activeAccountStorage

        let (accounts, lostAccountRecords) = accountStorage.allAccounts

        _allAccounts = accounts.reduce(into: [String: Account]()) { $0[$1.id] = $1 }
        _lostAccountRecords = lostAccountRecords

        syncAccounts()
    }

    private func syncAccounts() {
        _accounts = _allAccounts.filter { _, account in account.level >= level }
        _activeAccount = activeAccountStorage.activeAccountId(level: level).flatMap { _accounts[$0] } ?? _accounts.first?.value
    }

    var lostAccountRecords: [AccountRecord] {
        _lostAccountRecords.filter { $0.level >= level }
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

    // Only an explicit user action may discard an unavailable account's local record.
    func removeLostAccounts(ids: Set<String>) throws {
        let removableIds = Set(lostAccountRecords.compactMap { record in
            ids.contains(record.id) && _allAccounts[record.id] == nil ? record.id : nil
        })
        guard !removableIds.isEmpty else {
            return
        }

        // Keep the snapshot intact if the persistent transaction fails.
        try accountStorage.delete(accountIds: removableIds)
        _lostAccountRecords.removeAll { removableIds.contains($0.id) }
    }

    func clear() {
        accountStorage.clear()
        _lostAccountRecords = []
        _allAccounts = [:]
        _accounts = [:]
    }
}
