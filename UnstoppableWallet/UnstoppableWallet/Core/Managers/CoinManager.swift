import RxSwift
import CoinKit

class CoinManager {
    private let appConfigProvider: IAppConfigProvider
    private let coinKit: CoinKit.Kit

    private let subject = PublishSubject<Coin>()

    init(appConfigProvider: IAppConfigProvider, coinKit: CoinKit.Kit) {
        self.appConfigProvider = appConfigProvider
        self.coinKit = coinKit
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

    func coin(type: CoinType) -> Coin? {
        coinKit.coin(type: type)
    }

    func save(coin: Coin) {
        coinKit.save(coin: coin)
        subject.onNext(coin)
    }

}
