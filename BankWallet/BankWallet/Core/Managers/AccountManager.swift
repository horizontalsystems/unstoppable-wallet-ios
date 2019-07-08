import Foundation
import RxSwift

class AccountManager {
    private let storage: IAccountStorage

    var accounts: [Account] = []
    private var accountsSubject = PublishSubject<[Account]>()
    private var nonBackedUpCountSubject = PublishSubject<Int>()

    init(storage: IAccountStorage) {
        self.storage = storage

        accounts = storage.allAccounts
    }

    private func notifyAccountsChanged() {
        accountsSubject.onNext(accounts)
        nonBackedUpCountSubject.onNext(nonBackedUpCount)
    }

}

extension AccountManager: IAccountManager {

    var accountsObservable: Observable<[Account]> {
        return accountsSubject.asObservable()
    }

    var nonBackedUpCount: Int {
        return accounts.filter { !$0.backedUp }.count
    }

    var nonBackedUpCountObservable: Observable<Int> {
        return nonBackedUpCountSubject.asObservable()
    }

    func save(account: Account) {
        accounts.removeAll { $0.id == account.id }
        accounts.append(account)

        storage.save(account: account)
        notifyAccountsChanged()
    }

    func deleteAccount(id: String) {
        accounts.removeAll { $0.id == id }

        storage.deleteAccount(by: id)
        notifyAccountsChanged()
    }

    func setAccountBackedUp(id: String) {
        if let account = accounts.first(where: { $0.id == id }) {
            account.backedUp = true
            save(account: account)
        }

        storage.setAccountIsBackedUp(by: id)
        notifyAccountsChanged()
    }

}
