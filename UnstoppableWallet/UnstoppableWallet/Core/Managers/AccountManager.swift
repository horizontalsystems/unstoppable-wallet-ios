import RxSwift

class AccountManager {
    private let storage: IAccountStorage
    private let cache: AccountsCache = AccountsCache()

    private let accountsSubject = PublishSubject<[Account]>()
    private let deleteAccountSubject = PublishSubject<Account>()

    init(storage: IAccountStorage) {
        self.storage = storage
    }

}

extension AccountManager: IAccountManager {

    var accounts: [Account] {
        cache.accounts
    }

    func account(coinType: CoinType) -> Account? {
        accounts.first { account in
            coinType.canSupport(accountType: account.type)
        }
    }

    var accountsObservable: Observable<[Account]> {
        accountsSubject.asObservable()
    }

    var deleteAccountObservable: Observable<Account> {
        deleteAccountSubject.asObservable()
    }

    func preloadAccounts() {
        cache.set(accounts: storage.allAccounts)
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
    }

    func delete(account: Account) {
        storage.delete(account: account)
        cache.remove(account: account)

        accountsSubject.onNext(accounts)
        deleteAccountSubject.onNext(account)
    }

    func clear() {
        storage.clear()
        cache.set(accounts: [])

        accountsSubject.onNext(accounts)
    }

    func handleForeground() {
        let storedAccounts = storage.allAccounts

        let lostAccounts = cache.accounts.filter {
            storedAccounts.firstIndex(of: $0) == nil
        }
        lostAccounts.forEach { account in
            storage.delete(account: account)
            deleteAccountSubject.onNext(account)
        }

        cache.set(accounts: storedAccounts)
        accountsSubject.onNext(accounts)
    }

}

extension AccountManager {

    private class AccountsCache {
        private var array = [Account]()

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
    }

}
