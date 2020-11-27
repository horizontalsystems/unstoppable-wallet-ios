class BalanceErrorInteractor {
    private let adapterManager: IAdapterManager
    private let appConfigProvider: IAppConfigProvider

    init(adapterManager: IAdapterManager, appConfigProvider: IAppConfigProvider) {
        self.adapterManager = adapterManager
        self.appConfigProvider = appConfigProvider
    }

}

extension BalanceErrorInteractor: IBalanceErrorInteractor {

    var contactEmail: String {
        appConfigProvider.reportEmail
    }

    func refresh(wallet: Wallet) {
        adapterManager.refresh(wallet: wallet)
    }

}
