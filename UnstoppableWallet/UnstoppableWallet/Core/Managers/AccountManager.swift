import RxSwift
import RxRelay

class AccountManager {
    private let storage: AccountCachedStorage

    private let activeAccountRelay = PublishRelay<Account?>()
    private let accountsRelay = PublishRelay<[Account]>()
    private let accountUpdatedRelay = PublishRelay<Account>()
    private let accountDeletedRelay = PublishRelay<Account>()
    private let accountsLostRelay = BehaviorRelay<Bool>(value: false)

    private var lastCreatedAccount: Account?

    init(storage: AccountCachedStorage) {
        self.storage = storage
    }

    private func clearAccounts(ids: [String]) {
        ids.forEach {
            storage.delete(accountId: $0)
        }

        if storage.accounts.isEmpty {
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

}

class AccountCachedStorage {
    private let accountStorage: AccountStorage
    private let activeAccountStorage: ActiveAccountStorage

    private var _accounts: [String: Account]
    private var _activeAccount: Account?

    init(accountStorage: AccountStorage, activeAccountStorage: ActiveAccountStorage) {
        self.accountStorage = accountStorage
        self.activeAccountStorage = activeAccountStorage

        _accounts = accountStorage.allAccounts.reduce(into: [String: Account]()) { $0[$1.id] = $1 }
        _activeAccount = activeAccountStorage.activeAccountId.flatMap { _accounts[$0] }
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

    func account(id: String) -> Account? {
        _accounts[id]
    }

    func set(activeAccountId: String?) {
        activeAccountStorage.activeAccountId = activeAccountId
        _activeAccount = activeAccountId.flatMap { _accounts[$0] }
    }

    func save(account: Account) {
        accountStorage.save(account: account)
        _accounts[account.id] = account
    }

    func delete(account: Account) {
        accountStorage.delete(account: account)
        _accounts.removeValue(forKey: account.id)
    }

    func delete(accountId: String) {
        accountStorage.delete(accountId: accountId)
        _accounts.removeValue(forKey: accountId)
    }

    func clear() {
        accountStorage.clear()
        _accounts = [:]
    }

}
