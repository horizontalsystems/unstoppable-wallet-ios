import RxSwift
import RxCocoa

class FavoritesManager {
    private let storage: FavoriteCoinRecordStorage

    private let coinUidsUpdatedRelay = PublishRelay<()>()

    init(storage: FavoriteCoinRecordStorage) {
        self.storage = storage
    }

}

extension FavoritesManager {

    var coinUidsUpdatedObservable: Observable<()> {
        coinUidsUpdatedRelay.asObservable()
    }

    var allCoinUids: [String] {
        storage.favoriteCoinRecords.map { $0.coinUid }
    }

    func add(coinUid: String) {
        storage.save(favoriteCoinRecord: FavoriteCoinRecord(coinUid: coinUid))
        coinUidsUpdatedRelay.accept(())
    }

    func add(coinUids: [String]) {
        storage.save(favoriteCoinRecords: coinUids.map { FavoriteCoinRecord(coinUid: $0) })
        coinUidsUpdatedRelay.accept(())
    }

    func remove(coinUid: String) {
        storage.deleteFavoriteCoinRecord(coinUid: coinUid)
        coinUidsUpdatedRelay.accept(())
    }

    func isFavorite(coinUid: String) -> Bool {
        storage.favoriteCoinRecordExists(coinUid: coinUid)
    }

}
