import RxSwift

class CoinManager {
    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    private var defaultCoins: [Coin] {
        let suffix = appConfigProvider.testMode ? "t" : ""
        return [
            Coin(title: "Bitcoin", code: "BTC\(suffix)", type: .bitcoin),
            Coin(title: "Bitcoin Cash", code: "BCH\(suffix)", type: .bitcoinCash),
            Coin(title: "Ethereum", code: "ETH\(suffix)", type: .ethereum)
        ]
    }

}

extension CoinManager: ICoinManager {

    var coinsObservable: Observable<[Coin]> {
        return Observable.just(defaultCoins)
    }

}
