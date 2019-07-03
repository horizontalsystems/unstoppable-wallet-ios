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
                    self?.handleUpdated(accounts: accounts)
                })
                .disposed(by: disposeBag)
    }

    private func handleUpdated(accounts: [Account]) {
        delegate?.didUpdate(accounts: predefinedAccounts(accounts: accounts))
    }

    private func predefinedAccounts(accounts: [Account]) -> [Account] {
        return PredefinedAccountType.allCases.compactMap { type in
            return accounts.first { $0.type.predefinedAccountType == type }
        }
    }

}

extension ManageAccountsInteractor: IManageAccountsInteractor {

    var accounts: [Account] {
        return predefinedAccounts(accounts: accountManager.accounts)
    }

}
