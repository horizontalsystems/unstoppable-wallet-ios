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
        storage.coins + appConfigProvider.defaultCoins
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
    }

    func existingCoin(erc20Address: String) -> Coin? {
        coins.first { coin in
            if case .erc20(let address, _, _, _, _) = coin.type, address.lowercased() == erc20Address.lowercased() {
                return true
            }

            return false
        }
    }

    func save(coin: Coin) {
        if storage.save(coin: coin) {
            subject.onNext(coin)
        }
    }

}
