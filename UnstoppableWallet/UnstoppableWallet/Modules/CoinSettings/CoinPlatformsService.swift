import RxSwift
import RxRelay
import MarketKit

class CoinPlatformsService {
    private let approvePlatformsRelay = PublishRelay<CoinWithPlatforms>()
    private let rejectApprovePlatformsRelay = PublishRelay<Coin>()

    private let requestRelay = PublishRelay<Request>()
}

extension CoinPlatformsService {

    var approvePlatformsObservable: Observable<CoinWithPlatforms> {
        approvePlatformsRelay.asObservable()
    }

    var rejectApprovePlatformsObservable: Observable<Coin> {
        rejectApprovePlatformsRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approvePlatforms(marketCoin: MarketCoin, currentPlatforms: [Platform] = []) {
        guard marketCoin.platforms.count > 1 else {
            approvePlatformsRelay.accept(CoinWithPlatforms(coin: marketCoin.coin, platforms: marketCoin.platforms))
            return
        }

        let request = Request(marketCoin: marketCoin, currentPlatforms: currentPlatforms)
        requestRelay.accept(request)
    }

    func select(platforms: [Platform], coin: Coin) {
        let coinWithPlatforms = CoinWithPlatforms(coin: coin, platforms: platforms)
        approvePlatformsRelay.accept(coinWithPlatforms)
    }

    func cancel(coin: Coin) {
        rejectApprovePlatformsRelay.accept(coin)
    }

}

extension CoinPlatformsService {

    struct CoinWithPlatforms {
        let coin: Coin
        let platforms: [Platform]

        init(coin: Coin, platforms: [Platform] = []) {
            self.coin = coin
            self.platforms = platforms
        }
    }

    struct Request {
        let marketCoin: MarketCoin
        let currentPlatforms: [Platform]
    }

}
