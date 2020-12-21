import RxSwift

class ManageAccountsInteractor {
    weak var delegate: IManageAccountsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let derivationSettingsManager: IDerivationSettingsManager
    private let bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager

    init(predefinedAccountTypeManager: IPredefinedAccountTypeManager, accountManager: IAccountManager, derivationSettingsManager: IDerivationSettingsManager, bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager, walletManager: IWalletManager) {
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.derivationSettingsManager = derivationSettingsManager
        self.bitcoinCashCoinTypeManager = bitcoinCashCoinTypeManager

        accountManager.accountsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] accounts in
                    self?.delegate?.didUpdateAccounts()
                })
                .disposed(by: disposeBag)

        walletManager.walletsUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.didUpdateWallets()
                })
                .disposed(by: disposeBag)
    }

}

extension ManageAccountsInteractor: IManageAccountsInteractor {

    var predefinedAccountTypes: [PredefinedAccountType] {
        predefinedAccountTypeManager.allTypes
    }

    var hasAddressFormatSettings: Bool {
        !derivationSettingsManager.allActiveSettings.isEmpty || bitcoinCashCoinTypeManager.hasActiveSetting
    }

    func account(predefinedAccountType: PredefinedAccountType) -> Account? {
        predefinedAccountTypeManager.account(predefinedAccountType: predefinedAccountType)
    }

}
