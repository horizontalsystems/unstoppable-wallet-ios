class NoAccountInteractor {
    private let accountManager: IAccountManager
    private let accountCreator: IAccountCreator
    private let derivationSettingsManager: IDerivationSettingsManager
    private let bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager

    init(accountManager: IAccountManager, accountCreator: IAccountCreator, derivationSettingsManager: IDerivationSettingsManager, bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager) {
        self.accountManager = accountManager
        self.accountCreator = accountCreator
        self.derivationSettingsManager = derivationSettingsManager
        self.bitcoinCashCoinTypeManager = bitcoinCashCoinTypeManager
    }

}

extension NoAccountInteractor: INoAccountInteractor {

    func createAccount(predefinedAccountType: PredefinedAccountType) throws -> Account {
        try accountCreator.newAccount(predefinedAccountType: predefinedAccountType)
    }

    func save(account: Account) {
        accountManager.save(account: account)
    }

    func resetAddressFormatSettings() {
        derivationSettingsManager.resetStandardSettings()
        bitcoinCashCoinTypeManager.reset()
    }

}
