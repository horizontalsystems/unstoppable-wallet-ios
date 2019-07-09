import RxSwift

class ManageAccountsInteractor {
    weak var delegate: IManageAccountsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let accountManager: IAccountManager

    init(predefinedAccountTypeManager: IPredefinedAccountTypeManager, accountManager: IAccountManager) {
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.accountManager = accountManager

        accountManager.accountsObservable
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] accounts in
                    self?.delegate?.didUpdateAccounts()
                })
                .disposed(by: disposeBag)
    }

}

extension ManageAccountsInteractor: IManageAccountsInteractor {

    var predefinedAccountTypes: [IPredefinedAccountType] {
        return predefinedAccountTypeManager.allTypes
    }

    func account(predefinedAccountType: IPredefinedAccountType) -> Account? {
        return accountManager.account(predefinedAccountType: predefinedAccountType)
    }

}
