class BalanceErrorInteractor {
    private let walletManager: IWalletManager
    private let appConfigProvider: IAppConfigProvider

    init(walletManager: IWalletManager, appConfigProvider: IAppConfigProvider) {
        self.walletManager = walletManager
        self.appConfigProvider = appConfigProvider
    }

}

extension BalanceErrorInteractor: IBalanceErrorInteractor {

    var contactEmail: String {
        appConfigProvider.reportEmail
    }

    func refresh(wallet: Wallet) {
        walletManager.activeWallet(wallet: wallet)?.refresh()
    }

}
