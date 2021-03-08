import RxSwift
import RxRelay
import CoinKit

class MarketSearchService {
    private let disposeBag = DisposeBag()
    private let rateManager: IRateManager

    private let itemUpdatedRelay = PublishRelay<[Item]?>()
    private var items: [Item]? {
        didSet {
            itemUpdatedRelay.accept(items)
        }
    }

    var filter: String? {
        didSet {
            fetch()
        }
    }

    init(rateManager: IRateManager) {
        self.rateManager = rateManager
    }

    private func fetch() {
        guard let filter = filter, filter.count >= 2 else {
            items = nil
            return
        }

        items = rateManager
                    .searchCoins(text: filter)
                    .map { Item(coinTitle: $0.name, coinCode: $0.code, coinType: $0.coinType) }
    }

}

extension MarketSearchService {

    var itemUpdatedObservable: Observable<[Item]?> {
        itemUpdatedRelay.asObservable()
    }

}

extension MarketSearchService {

    struct Item {
        let coinTitle: String
        let coinCode: String
        let coinType: CoinType
    }

}
