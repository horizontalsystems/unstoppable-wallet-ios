import RxSwift
import RxRelay
import Combine
import HsExtensions

class BackupManager {
    private let accountManager: AccountManager

    private let disposeBag = DisposeBag()

    private let allBackedUpRelay = PublishRelay<Bool>()

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
        subscribe(disposeBag, accountManager.accountsObservable) { [weak self] _ in self?.updateAllBackedUp() }
    }

    private func updateAllBackedUp() {
        allBackedUpRelay.accept(allBackedUp)
    }

}

extension BackupManager {

    var allBackedUp: Bool {
        accountManager.accounts.allSatisfy { $0.backedUp }
    }

    var allBackedUpObservable: Observable<Bool> {
        allBackedUpRelay.asObservable()
    }

    func setAccountBackedUp(id: String) {
        guard let account = accountManager.account(id: id) else {
            return
        }

        account.backedUp = true
        accountManager.update(account: account)
    }

}
