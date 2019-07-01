import Foundation
import RxSwift

class AccountManager {
    private let secureStorage: ISecureStorage

    var accounts: [Account] = []
    private var accountsSubject = PublishSubject<[Account]>()

    init(secureStorage: ISecureStorage) {
        self.secureStorage = secureStorage
    }

}

extension AccountManager: IAccountManager {

    var accountsObservable: Observable<[Account]> {
        return accountsSubject.asObservable()
    }

    func save(account: Account) {
        accounts.removeAll { $0.id == account.id }
        accounts.append(account)
        accountsSubject.onNext(accounts)
    }

    func deleteAccount(id: String) {
        accounts.removeAll { $0.id == id }
        accountsSubject.onNext(accounts)
    }

    func setAccountBackedUp(id: String) {
        if var account = accounts.first(where: { $0.id == id }) {
            account.backedUp = true
            save(account: account)
        }
        accountsSubject.onNext(accounts)
    }

}
