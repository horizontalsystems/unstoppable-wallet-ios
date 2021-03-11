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

    var groupedCoins: (featured: [Coin], regular: [Coin]) {
        var featured = [Coin]()
        var regular = [Coin]()

        var coins = coinKit.coins

        for featuredCoinType in appConfigProvider.featuredCoinTypes {
            if let index = coins.firstIndex { $0.type == featuredCoinType } {
                featured.append(coins.remove(at: index))
            }
        }

        return (featured: featured, regular: coins)
    }

    func coin(type: CoinType) -> Coin? {
        coinKit.coin(type: type)
    }

    func save(coin: Coin) {
        coinKit.save(coin: coin)
        subject.onNext(coin)
    }

}
