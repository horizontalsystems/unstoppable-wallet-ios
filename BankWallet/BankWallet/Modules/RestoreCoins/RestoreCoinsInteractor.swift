class RestoreCoinsInteractor {
    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

}

extension RestoreCoinsInteractor: IRestoreCoinsInteractor {

    var coins: [Coin] {
        appConfigProvider.coins
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
    }

}
