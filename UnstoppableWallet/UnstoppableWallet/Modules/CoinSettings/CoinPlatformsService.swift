import RxSwift
import RxRelay
import MarketKit

class CoinPlatformsService {
    private let approvePlatformsRelay = PublishRelay<CoinWithPlatforms>()
    private let rejectApprovePlatformsRelay = PublishRelay<FullCoin>()

    private let requestRelay = PublishRelay<Request>()
}

extension CoinPlatformsService {

    var approvePlatformsObservable: Observable<CoinWithPlatforms> {
        approvePlatformsRelay.asObservable()
    }

    var rejectApprovePlatformsObservable: Observable<FullCoin> {
        rejectApprovePlatformsRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approvePlatforms(fullCoin: FullCoin, currentPlatforms: [Platform] = []) {
        let supportedPlatforms = fullCoin.supportedPlatforms

        guard supportedPlatforms.count > 1 else {
            approvePlatformsRelay.accept(CoinWithPlatforms(coin: fullCoin.coin, platforms: supportedPlatforms))
            return
        }

        let request = Request(fullCoin: fullCoin, currentPlatforms: currentPlatforms)
        requestRelay.accept(request)
    }

    func select(platforms: [Platform], coin: Coin) {
        let coinWithPlatforms = CoinWithPlatforms(coin: coin, platforms: platforms)
        approvePlatformsRelay.accept(coinWithPlatforms)
    }

    func cancel(fullCoin: FullCoin) {
        rejectApprovePlatformsRelay.accept(fullCoin)
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
        let fullCoin: FullCoin
        let currentPlatforms: [Platform]
    }

}
