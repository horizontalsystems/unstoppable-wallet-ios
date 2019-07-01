import RxSwift

class ManageAccountsInteractor {
    weak var delegate: IManageAccountsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

}

extension ManageAccountsInteractor: IManageAccountsInteractor {

    var accounts: [Account] {
        return accountManager.accounts
    }

}
