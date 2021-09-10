import RxSwift
import RxRelay
import MarketKit

class MarketSearchService {
    private let disposeBag = DisposeBag()
    private let marketKit: Kit

    private let coinsUpdatedRelay = PublishRelay<[Coin]>()
    private var coins: [Coin] = [] {
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
                coins = try marketKit.coins(filter: filter)
            } catch {
                coins = []
            }
        }

    }

}

extension MarketSearchService {

    var coinsUpdatedObservable: Observable<[Coin]> {
        coinsUpdatedRelay.asObservable()
    }

}
