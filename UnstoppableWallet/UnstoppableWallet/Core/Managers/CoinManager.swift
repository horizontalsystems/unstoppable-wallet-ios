import RxSwift

class CoinManager {
    private let appConfigProvider: IAppConfigProvider
    private let storage: ICoinStorage

    private let subject = PublishSubject<Coin>()

    init(appConfigProvider: IAppConfigProvider, storage: ICoinStorage) {
        self.appConfigProvider = appConfigProvider
        self.storage = storage
    }

}

extension CoinManager: ICoinManager {

    var coinAddedObservable: Observable<Coin> {
        subject.asObservable()
    }

    var coins: [Coin] {
        let defaultCoins = appConfigProvider.defaultCoins
        let storedCoins = storage.coins.filter { coin in
            !defaultCoins.contains { $0.type == coin.type }
        }

        return storedCoins + defaultCoins
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
    }

    func save(coin: Coin) {
        if storage.save(coin: coin) {
            subject.onNext(coin)
        }
    }

}
