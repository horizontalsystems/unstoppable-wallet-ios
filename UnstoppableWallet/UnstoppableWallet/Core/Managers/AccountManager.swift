import RxSwift
import RxRelay
import CoinKit

class AccountManager {
    private let storage: IAccountStorage
    private let activeAccountStorage: IActiveAccountStorage
    private let cache: AccountsCache = AccountsCache()

    private let activeAccountRelay = PublishRelay<Account?>()
    private let accountsSubject = PublishSubject<[Account]>()
    private let deleteAccountSubject = PublishSubject<Account>()
    private let lostAccountsRelay = BehaviorRelay<Bool>(value: false)

    init(storage: IAccountStorage, activeAccountStorage: IActiveAccountStorage) {
        self.storage = storage
        self.activeAccountStorage = activeAccountStorage
    }

    private func clearAccounts(ids: [String]) {
        ids.forEach {
            storage.delete(accountId: $0)
        }

        if storage.allAccounts.isEmpty {
            lostAccountsRelay.accept(true)
        }
    }

}

extension AccountManager: IAccountManager {

    var activeAccount: Account? {
        cache.activeAccount
    }

    func set(activeAccountId: String?) {
        guard cache.activeAccount?.id != activeAccountId else {
            return
        }

        activeAccountStorage.activeAccountId = activeAccountId
        cache.set(activeAccountId: activeAccountId)
        activeAccountRelay.accept(activeAccount)
    }

    var accounts: [Account] {
        cache.accounts
    }

    func account(id: String) -> Account? {
        accounts.first { $0.id == id }
    }

    var activeAccountObservable: Observable<Account?> {
        activeAccountRelay.asObservable()
    }

    var accountsObservable: Observable<[Account]> {
        accountsSubject.asObservable()
    }

    var deleteAccountObservable: Observable<Account> {
        deleteAccountSubject.asObservable()
    }

    var lostAccountsObservable: Observable<Bool> {
        lostAccountsRelay.asObservable()
    }

    func preloadAccounts() {
        cache.set(accounts: storage.allAccounts)
        cache.set(activeAccountId: activeAccountStorage.activeAccountId)
    }

    func update(account: Account) {
        storage.save(account: account)
        cache.update(account: account)

        accountsSubject.onNext(accounts)
    }

    func save(account: Account) {
        storage.save(account: account)
        cache.insert(account: account)

        accountsSubject.onNext(accounts)

        set(activeAccountId: account.id)
    }

    func delete(account: Account) {
        storage.delete(account: account)
        cache.remove(account: account)

        accountsSubject.onNext(accounts)
        deleteAccountSubject.onNext(account)

        if account == activeAccount {
            set(activeAccountId: accounts.first?.id)
        }
    }

    func clear() {
        storage.clear()
        cache.set(accounts: [])

        accountsSubject.onNext(accounts)
        set(activeAccountId: nil)
    }

    func handleLaunch() {
        let lostAccountIds = storage.lostAccountIds()
        guard !lostAccountIds.isEmpty else {
            return
        }

        clearAccounts(ids: lostAccountIds)
    }

    func handleForeground() {
        let lostAccountIds = storage.lostAccountIds()
        guard !lostAccountIds.isEmpty else {
            return
        }

        clearAccounts(ids: lostAccountIds)

        let lostAccounts = cache.accounts.filter { account in
            lostAccountIds.contains(account.id)
        }

        lostAccounts.forEach { account in
            cache.remove(account: account)
            deleteAccountSubject.onNext(account)
        }

        accountsSubject.onNext(accounts)
    }

}

extension AccountManager {

    private class AccountsCache {
        private var array = [Account]()
        var activeAccount: Account?

        var accounts: [Account] {
            array
        }

        func set(accounts: [Account]) {
            array = accounts
        }

        func insert(account: Account) {
            array.append(account)
        }

        func update(account: Account) {
            if let index = array.firstIndex(of: account) {
                array[index] = account
            }
        }

        func remove(account: Account) {
            array.removeAll { $0 == account }
        }

        func set(activeAccountId: String?) {
            activeAccount = array.first { $0.id == activeAccountId }
        }
    }

}
