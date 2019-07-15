import RxSwift

class BackupManager {
    private let accountManager: IAccountManager
    private let nonBackedUpCountSubject = PublishSubject<Int>()

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

}

extension BackupManager: IBackupManager {

    var nonBackedUpCount: Int {
        return accountManager.accounts.filter { !$0.backedUp }.count
    }

    var nonBackedUpCountObservable: Observable<Int> {
        return nonBackedUpCountSubject.asObservable()
    }

    func setAccountBackedUp(id: String) {
        guard let account = accountManager.accounts.first(where: { $0.id == id }) else {
            return
        }

        account.backedUp = true
        accountManager.save(account: account)

        nonBackedUpCountSubject.onNext(nonBackedUpCount)
    }

}
