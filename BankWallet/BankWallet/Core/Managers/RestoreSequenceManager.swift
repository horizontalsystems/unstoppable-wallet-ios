class RestoreSequenceManager {
    private let walletManager: IWalletManager
    private let derivationSettingsManager: IDerivationSettingsManager
    private let accountCreator: IAccountCreator
    private let accountManager: IAccountManager

    init(walletManager: IWalletManager, derivationSettingsManager: IDerivationSettingsManager, accountCreator: IAccountCreator, accountManager: IAccountManager) {
        self.walletManager = walletManager
        self.derivationSettingsManager = derivationSettingsManager
        self.accountCreator = accountCreator
        self.accountManager = accountManager
    }

    private func createWallets(coins: [Coin], derivationSettings: [DerivationSetting], accountType: AccountType) {
        let account = accountCreator.restoredAccount(accountType: accountType)
        accountManager.save(account: account)

        derivationSettingsManager.save(settings: derivationSettings)

        let wallets: [Wallet] = coins.map { coin in
            Wallet(coin: coin, account: account)
        }
        walletManager.save(wallets: wallets)
    }

}

extension RestoreSequenceManager: IRestoreSequenceManager {

    func onAccountCheck(accountType: AccountType, predefinedAccountType: PredefinedAccountType?, coins: ((AccountType, PredefinedAccountType) -> ())) {
        guard let predefinedAccountType = predefinedAccountType else {
            return
        }

        coins(accountType, predefinedAccountType)
    }

    func onCoinsSelect(coins: [Coin], accountType: AccountType?, derivationSettings: [DerivationSetting], finish: () -> ()?) {
        guard let accountType = accountType else {
            return
        }

        createWallets(coins: coins, derivationSettings: derivationSettings, accountType: accountType)
        finish()
    }

}
