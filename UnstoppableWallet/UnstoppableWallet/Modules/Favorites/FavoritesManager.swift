import RxSwift
import RxCocoa

class FavoritesManager {
    private let storage: IFavoriteCoinRecordStorage

    private let coinUidsUpdatedRelay = PublishRelay<()>()

    init(storage: IFavoriteCoinRecordStorage) {
        self.storage = storage
    }

}

extension FavoritesManager {

    var dataUpdatedObservable: Observable<()> {
        coinUidsUpdatedRelay.asObservable()
    }

    var allCoinUids: [String] {
        storage.favoriteCoinRecords.map { $0.coinUid }
    }

    func add(coinUid: String) {
        storage.save(favoriteCoinRecord: FavoriteCoinRecord(coinUid: coinUid))
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
