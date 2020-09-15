class RestoreService {
    private let walletManager: IWalletManager
    private let accountCreator: IAccountCreator
    private let accountManager: IAccountManager

    var predefinedAccountType: PredefinedAccountType?
    var accountType: AccountType?

    init(predefinedAccountType: PredefinedAccountType?, walletManager: IWalletManager, accountCreator: IAccountCreator, accountManager: IAccountManager) {
        self.predefinedAccountType = predefinedAccountType
        self.walletManager = walletManager
        self.accountCreator = accountCreator
        self.accountManager = accountManager
    }

    func restoreAccount(coins: [Coin] = []) throws {
        guard let accountType = accountType else {
            throw RestoreError.noAccountType
        }

        let account = accountCreator.restoredAccount(accountType: accountType)
        accountManager.save(account: account)

        guard !coins.isEmpty else {
            return
        }

        let wallets: [Wallet] = coins.map { coin in
            Wallet(coin: coin, account: account)
        }
        walletManager.save(wallets: wallets)
    }

}

extension RestoreService {

    enum RestoreError: Error {
        case noAccountType
    }

}
