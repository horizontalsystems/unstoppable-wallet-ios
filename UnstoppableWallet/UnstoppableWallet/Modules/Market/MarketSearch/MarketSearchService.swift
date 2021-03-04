import RxSwift
import RxRelay
import CoinKit

class MarketSearchService {
    private let disposeBag = DisposeBag()
    private let rateManager: IRateManager

    private let itemUpdatedRelay = PublishRelay<[Item]>()
    private var items = [Item]() {
        didSet {
            itemUpdatedRelay.accept(items)
        }
    }

    var filter: String? {
        didSet {
            updateItems()
        }
    }

    init(rateManager: IRateManager) {
        self.rateManager = rateManager
    }

    private func updateItems() {
        guard let filter = filter else {
            items = []
            return
        }
        return items = filter.count < 2 ? [] : [
            Item(coinTitle: "1X Short Bitcoin Cash Token", coinCode: "bchhedge", coinType: CoinType(id: "erc20|0x02e88a689fdfb920e7aa6174fb7ab72add3c5694")!),
            Item(coinTitle: "1X Short Bitcoin Token", coinCode: "hedge", coinType: CoinType(id: "erc20|0x1fa3bc860bf823d792f04f662f3aa3a500a68814")!),
            Item(coinTitle: "erc20|0x627e2ee3dbda546e168eaaff25a2c5212e4a95a0", coinCode: "ibvol", coinType: CoinType(id: "erc20|0x627e2ee3dbda546e168eaaff25a2c5212e4a95a0")!),
            Item(coinTitle: "AEROTOKEN", coinCode: "bchhedge", coinType: CoinType(id: "erc20|0x8c9e4cf756b9d01d791b95bc2d0913ef2bf03784")!),
        ]
    }

}

extension MarketSearchService {

    var itemUpdatedObservable: Observable<[Item]> {
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
