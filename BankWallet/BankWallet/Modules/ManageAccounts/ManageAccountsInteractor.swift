import RxSwift

class ManageAccountsInteractor {
    weak var delegate: IManageAccountsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager

        accountManager.accountsObservable
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] accounts in
                    self?.delegate?.didUpdate(accounts: accounts)
                })
                .disposed(by: disposeBag)
    }

}

extension ManageAccountsInteractor: IManageAccountsInteractor {

    var accounts: [Account] {
        return accountManager.accounts
    }

}
