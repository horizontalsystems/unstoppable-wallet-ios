import RxSwift
import RxRelay

class ManageAccountsServiceNew {
    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

}

extension ManageAccountsServiceNew {

    var accounts: [Account] {
        accountManager.accounts
    }

    var accountsObservable: Observable<[Account]> {
        accountManager.accountsObservable
    }

}
