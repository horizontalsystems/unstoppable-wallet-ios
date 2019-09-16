class CreateWalletInteractor {
    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

}

extension CreateWalletInteractor: ICreateWalletInteractor {

    var featuredCoins: [Coin] {
        return appConfigProvider.featuredCoins
    }

    func createWallet(coin: Coin) {
        // todo: implement this
    }

}
