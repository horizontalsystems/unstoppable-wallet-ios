class CreateWalletInteractor {
    private let appConfigProvider: IAppConfigProvider
    private let accountCreator: IAccountCreator

    init(appConfigProvider: IAppConfigProvider, accountCreator: IAccountCreator) {
        self.appConfigProvider = appConfigProvider
        self.accountCreator = accountCreator
    }

}

extension CreateWalletInteractor: ICreateWalletInteractor {

    var featuredCoins: [Coin] {
        return appConfigProvider.featuredCoins
    }

    func createWallet(coin: Coin) throws {
        try accountCreator.createNewAccount(coin: coin)
    }

}
