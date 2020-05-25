import RxSwift

class BackupManager {
    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

    private func isAllBackedUp(accounts: [Account]) -> Bool {
        return accounts.allSatisfy { $0.backedUp }
    }

}

extension BackupManager: IBackupManager {

    var allBackedUp: Bool {
        return isAllBackedUp(accounts: accountManager.accounts)
    }

    var allBackedUpObservable: Observable<Bool> {
        return accountManager.accountsObservable.map { [unowned self] accounts in
            return self.isAllBackedUp(accounts: accounts)
        }
    }

    func setAccountBackedUp(id: String) {
        guard let account = accountManager.accounts.first(where: { $0.id == id }) else {
            return
        }

        account.backedUp = true
        accountManager.update(account: account)
    }

}
