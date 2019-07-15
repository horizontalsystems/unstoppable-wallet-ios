import RxSwift

class AccountManager {
    private let storage: IAccountStorage
    private let cache: AccountsCache = AccountsCache()

    private let accountsSubject = PublishSubject<[Account]>()

    init(storage: IAccountStorage) {
        self.storage = storage
    }

}

extension AccountManager: IAccountManager {

    var accounts: [Account] {
        return cache.accounts
    }

    var accountsObservable: Observable<[Account]> {
        return accountsSubject.asObservable()
    }

    func preloadAccounts() {
        cache.set(accounts: storage.allAccounts)
    }

    func save(account: Account) {
        storage.save(account: account)
        cache.insert(account: account)

        accountsSubject.onNext(accounts)
    }

    func deleteAccount(id: String) {
        storage.deleteAccount(by: id)
        cache.removeAccount(id: id)

        accountsSubject.onNext(accounts)
    }

}

extension AccountManager {

    class AccountsCache {
        private var array = [Account]()

        var accounts: [Account] {
            return array
        }

        func set(accounts: [Account]) {
            array = accounts
        }

        func insert(account: Account) {
            if let index = array.firstIndex(of: account) {
                array[index] = account
            } else {
                array.append(account)
            }
        }

        func removeAccount(id: String) {
            array.removeAll { $0.id == id }
        }
    }

}
