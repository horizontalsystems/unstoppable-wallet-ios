import RxSwift

class ManageAccountsInteractor {
    weak var delegate: IManageAccountsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let derivationSettingsManager: IDerivationSettingsManager

    init(predefinedAccountTypeManager: IPredefinedAccountTypeManager, accountManager: IAccountManager, derivationSettingsManager: IDerivationSettingsManager) {
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.derivationSettingsManager = derivationSettingsManager

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

    var allActiveDerivationSettings: [(setting: DerivationSetting, wallets: [Wallet])] {
        derivationSettingsManager.allActiveSettings
    }

    func account(predefinedAccountType: PredefinedAccountType) -> Account? {
        predefinedAccountTypeManager.account(predefinedAccountType: predefinedAccountType)
    }

}
