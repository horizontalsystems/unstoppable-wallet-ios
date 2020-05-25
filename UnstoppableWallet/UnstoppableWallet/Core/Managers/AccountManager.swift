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
        return cache.accounts
    }

    func account(coinType: CoinType) -> Account? {
        return accounts.first { account in
            return coinType.canSupport(accountType: account.type)
        }
    }

    var accountsObservable: Observable<[Account]> {
        return accountsSubject.asObservable()
    }

    var deleteAccountObservable: Observable<Account> {
        return deleteAccountSubject.asObservable()
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

}

extension AccountManager {

    private class AccountsCache {
        private var array = [Account]()

        var accounts: [Account] {
            return array
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
