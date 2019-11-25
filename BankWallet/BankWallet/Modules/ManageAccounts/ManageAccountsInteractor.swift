import RxSwift

class ManageAccountsInteractor {
    weak var delegate: IManageAccountsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let accountCreator: IAccountCreator

    init(predefinedAccountTypeManager: IPredefinedAccountTypeManager, accountManager: IAccountManager, accountCreator: IAccountCreator) {
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.accountCreator = accountCreator

        accountManager.accountsObservable
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] accounts in
                    self?.delegate?.didUpdateAccounts()
                })
                .disposed(by: disposeBag)
    }

}

extension ManageAccountsInteractor: IManageAccountsInteractor {

    var predefinedAccountTypes: [PredefinedAccountType] {
        predefinedAccountTypeManager.allTypes
    }

    func account(predefinedAccountType: PredefinedAccountType) -> Account? {
        predefinedAccountTypeManager.account(predefinedAccountType: predefinedAccountType)
    }

}
