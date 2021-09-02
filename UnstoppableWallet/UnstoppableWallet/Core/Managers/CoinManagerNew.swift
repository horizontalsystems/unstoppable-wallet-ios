import RxSwift
import RxRelay
import MarketKit

class CoinManagerNew {
    private let marketKit: Kit

//    private let coinsAddedRelay = PublishRelay<[Coin]>()

    init(marketKit: Kit) {
        self.marketKit = marketKit
    }

}

extension CoinManagerNew {

//    var coinsAddedObservable: Observable<[Coin]> {
//        coinsAddedRelay.asObservable()
//    }

    func marketCoins(filter: String = "", limit: Int = 20) throws -> [MarketCoin] {
        try marketKit.marketCoins(filter: filter, limit: limit)
    }

    func marketCoins(coinUids: [String]) throws -> [MarketCoin] {
        try marketKit.marketCoins(coinUids: coinUids)
    }

    func platformCoin(coinType: CoinType) throws -> PlatformCoin? {
        try marketKit.platformCoin(coinType: coinType)
    }

    func platformCoins() throws -> [PlatformCoin] {
        try marketKit.platformCoins()
    }

//    func save(coins: [Coin]) {
//        coinKit.save(coins: coins)
//        coinsAddedRelay.accept(coins)
//    }

}
