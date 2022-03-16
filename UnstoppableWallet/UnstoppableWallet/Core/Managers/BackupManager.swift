import RxSwift

class BackupManager {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }

}

extension BackupManager {

    var allBackedUp: Bool {
        accountManager.accounts.allSatisfy { $0.backedUp }
    }

    var allBackedUpObservable: Observable<Bool> {
        accountManager.accountsObservable.map { $0.allSatisfy { $0.backedUp } }
    }

    func setAccountBackedUp(id: String) {
        guard let account = accountManager.account(id: id) else {
            return
        }

        account.backedUp = true
        accountManager.update(account: account)
    }

}
