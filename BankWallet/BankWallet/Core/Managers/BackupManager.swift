import RxSwift

class BackupManager {
    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

    private func getCount(accounts: [Account]) -> Int {
        return accounts.filter { !$0.backedUp }.count
    }

}

extension BackupManager: IBackupManager {

    var nonBackedUpCount: Int {
        return getCount(accounts: accountManager.accounts)
    }

    var nonBackedUpCountObservable: Observable<Int> {
        return accountManager.accountsObservable.map { [unowned self] accounts in
            return self.getCount(accounts: accounts)
        }
    }

    func setAccountBackedUp(id: String) {
        guard let account = accountManager.accounts.first(where: { $0.id == id }) else {
            return
        }

        account.backedUp = true
        accountManager.save(account: account)
    }

}
