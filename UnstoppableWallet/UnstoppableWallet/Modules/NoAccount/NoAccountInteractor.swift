class NoAccountInteractor {
    private let accountManager: IAccountManager
    private let accountCreator: IAccountCreator
    private let walletManager: IWalletManager
    private let derivationSettingsManager: IDerivationSettingsManager
    private let bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager

    init(accountManager: IAccountManager, accountCreator: IAccountCreator, walletManager: IWalletManager, derivationSettingsManager: IDerivationSettingsManager, bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager) {
        self.accountManager = accountManager
        self.accountCreator = accountCreator
        self.walletManager = walletManager
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

    func createWallet(coin: Coin, account: Account) {
        let wallet = Wallet(coin: coin, account: account)
        walletManager.save(wallets: [wallet])
    }

    func resetAddressFormatSettings() {
        derivationSettingsManager.resetStandardSettings()
        bitcoinCashCoinTypeManager.reset()
    }

}
