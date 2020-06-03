class CoinManager {
    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

}

extension CoinManager: ICoinManager {

    var coins: [Coin] {
        appConfigProvider.defaultCoins
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
    }

}
