class BalanceErrorInteractor {
    private let adapterManager: AdapterManager
    private let appConfigProvider: AppConfigProvider

    init(adapterManager: AdapterManager, appConfigProvider: AppConfigProvider) {
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
