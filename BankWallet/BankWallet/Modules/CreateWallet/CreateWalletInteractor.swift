class CreateWalletInteractor {
    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

}

extension CreateWalletInteractor: ICreateWalletInteractor {

    var featuredCoins: [FeaturedCoin] {
        return appConfigProvider.featureCoins
    }

    func createWallet(coins: [Coin]) {
        // todo: implement this
    }

}
