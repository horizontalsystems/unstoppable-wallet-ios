import RxSwift
import RxRelay
import MarketKit

class MarketSearchService {
    private let disposeBag = DisposeBag()
    private let marketKit: Kit

    private let coinsUpdatedRelay = PublishRelay<[FullCoin]>()
    private var coins: [FullCoin] = [] {
        didSet {
            coinsUpdatedRelay.accept(coins)
        }
    }

    var filter: String = "" {
        didSet {
            fetch()
        }
    }

    init(marketKit: Kit) {
        self.marketKit = marketKit
    }

    private func fetch() {
        if filter.isEmpty {
            coins = []
        } else {
            do {
                coins = try marketKit.fullCoins(filter: filter)
            } catch {
                coins = []
            }
        }

    }

}

extension MarketSearchService {

    var coinsUpdatedObservable: Observable<[FullCoin]> {
        coinsUpdatedRelay.asObservable()
    }

}
