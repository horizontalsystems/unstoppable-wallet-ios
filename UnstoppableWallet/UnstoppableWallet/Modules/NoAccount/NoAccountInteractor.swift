class NoAccountInteractor {
    private let accountManager: IAccountManager
    private let accountCreator: IAccountCreator
    private let derivationSettingsManager: IDerivationSettingsManager

    init(accountManager: IAccountManager, accountCreator: IAccountCreator, derivationSettingsManager: IDerivationSettingsManager) {
        self.accountManager = accountManager
        self.accountCreator = accountCreator
        self.derivationSettingsManager = derivationSettingsManager
    }

}

extension NoAccountInteractor: INoAccountInteractor {

    func createAccount(predefinedAccountType: PredefinedAccountType) throws -> Account {
        try accountCreator.newAccount(predefinedAccountType: predefinedAccountType)
    }

    func save(account: Account) {
        accountManager.save(account: account)
    }

    func derivationSettings(coin: Coin) -> DerivationSetting? {
        derivationSettingsManager.setting(coinType: coin.type)
    }

    func resetDerivationSettings() {
        derivationSettingsManager.reset()
    }

}
