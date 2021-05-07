import RxSwift
import RxRelay
import CoinKit

class CoinManager {
    private let appConfigProvider: IAppConfigProvider
    private let coinKit: CoinKit.Kit

    private let coinsAddedRelay = PublishRelay<[Coin]>()

    init(appConfigProvider: IAppConfigProvider, coinKit: CoinKit.Kit) {
        self.appConfigProvider = appConfigProvider
        self.coinKit = coinKit
    }

}

extension CoinManager: ICoinManager {

    var coinsAddedObservable: Observable<[Coin]> {
        coinsAddedRelay.asObservable()
    }

    var coins: [Coin] {
        coinKit.coins
    }

    var groupedCoins: (featured: [Coin], regular: [Coin]) {
        var featured = [Coin]()
        var coins = coinKit.coins

        for featuredCoinType in appConfigProvider.featuredCoinTypes {
            if let index = coins.firstIndex(where: { $0.type == featuredCoinType }) {
                featured.append(coins.remove(at: index))
            }
        }

        return (featured: featured, regular: coins)
    }

    func coin(type: CoinType) -> Coin? {
        coinKit.coin(type: type)
    }

    func save(coins: [Coin]) {
        coinKit.save(coins: coins)
        coinsAddedRelay.accept(coins)
    }

}
