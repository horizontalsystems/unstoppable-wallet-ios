class BalanceErrorInteractor {
    private let adapterManager: AdapterManager
    private let appConfigProvider: IAppConfigProvider

    init(adapterManager: AdapterManager, appConfigProvider: IAppConfigProvider) {
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
