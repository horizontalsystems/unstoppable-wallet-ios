import RxSwift
import CoinKit

class CoinManager {
    private let appConfigProvider: IAppConfigProvider
    private let coinKit: CoinKit
    private let storage: ICoinStorage

    private let subject = PublishSubject<Coin>()

    init(appConfigProvider: IAppConfigProvider, coinKit: CoinKit, storage: ICoinStorage) {
        self.appConfigProvider = appConfigProvider
        self.coinKit = coinKit
        self.storage = storage
    }

}

extension CoinManager: ICoinManager {

    var coinAddedObservable: Observable<Coin> {
        subject.asObservable()
    }

    var coins: [Coin] {
        coinKit.coins
    }

    var featuredCoins: [Coin] {
        appConfigProvider.featuredCoins
    }

    func save(coin: Coin) {
        coinKit.save(coin: coin)
        subject.onNext(coin)
    }

}
