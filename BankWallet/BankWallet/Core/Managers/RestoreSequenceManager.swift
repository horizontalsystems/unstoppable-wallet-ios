class RestoreSequenceManager {
    private let walletManager: IWalletManager
    private let settingsManager: IBlockchainSettingsManager
    private let accountCreator: IAccountCreator
    private let accountManager: IAccountManager

    init(walletManager: IWalletManager, settingsManager: IBlockchainSettingsManager, accountCreator: IAccountCreator, accountManager: IAccountManager) {
        self.walletManager = walletManager
        self.settingsManager = settingsManager
        self.accountCreator = accountCreator
        self.accountManager = accountManager
    }

    private func createWallets(coins: [Coin], settings: [BlockchainSetting], accountType: AccountType) {
        let account = accountCreator.restoredAccount(accountType: accountType)
        accountManager.save(account: account)

        settingsManager.save(settings: settings)

        let wallets: [Wallet] = coins.map { coin in
            Wallet(coin: coin, account: account)
        }
        walletManager.save(wallets: wallets)
    }

}

extension RestoreSequenceManager: IRestoreSequenceFactory {

    func onAccountCheck(accountType: AccountType, predefinedAccountType: PredefinedAccountType?, coins: ((AccountType, PredefinedAccountType, RestoreRouter.ProceedMode) -> ())) {
        guard let predefinedAccountType = predefinedAccountType else {
            return
        }

        let proceedMode: RestoreRouter.ProceedMode = predefinedAccountType == .standard ? .next : .restore
        coins(accountType, predefinedAccountType, proceedMode)
    }

    func onCoinsSelect(coins: [Coin], accountType: AccountType?, predefinedAccountType: PredefinedAccountType?, settings: () -> ()?, finish: () -> ()?) {
        guard let predefinedAccountType = predefinedAccountType else {
            return
        }
        guard let accountType = accountType else {
            return
        }

        if predefinedAccountType == .standard {
            settings()
        } else {
            createWallets(coins: coins, settings: [], accountType: accountType)
            finish()
        }
    }

    func onSettingsConfirm(accountType: AccountType?, coins: [Coin]?, settings: [BlockchainSetting], success: (() -> ())) {
        guard let coins = coins, let accountType = accountType else {
            return
        }

        createWallets(coins: coins, settings: settings, accountType: accountType)
        success()
    }

}
