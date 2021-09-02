class BalanceErrorInteractor {
    private let adapterManager: AdapterManagerNew
    private let appConfigProvider: IAppConfigProvider

    init(adapterManager: AdapterManagerNew, appConfigProvider: IAppConfigProvider) {
        self.adapterManager = adapterManager
        self.appConfigProvider = appConfigProvider
    }

}

extension BalanceErrorInteractor: IBalanceErrorInteractor {

    var contactEmail: String {
        appConfigProvider.reportEmail
    }

    func refresh(wallet: WalletNew) {
        adapterManager.refresh(wallet: wallet)
    }

}
