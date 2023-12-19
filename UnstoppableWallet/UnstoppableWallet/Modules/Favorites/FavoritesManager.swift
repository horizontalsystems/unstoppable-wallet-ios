import RxCocoa
import RxSwift
import WidgetKit

class FavoritesManager {
    private let storage: FavoriteCoinRecordStorage
    private let sharedStorage: SharedLocalStorage

    private let coinUidsUpdatedRelay = PublishRelay<Void>()

    init(storage: FavoriteCoinRecordStorage, sharedStorage: SharedLocalStorage) {
        self.storage = storage
        self.sharedStorage = sharedStorage

        syncSharedStorage()
    }

    private func syncSharedStorage() {
        sharedStorage.set(value: allCoinUids, for: AppWidgetConstants.keyFavoriteCoinUids)
        WidgetCenter.shared.reloadTimelines(ofKind: AppWidgetConstants.watchlistWidgetKind)
    }
}

extension FavoritesManager {
    var coinUidsUpdatedObservable: Observable<Void> {
        coinUidsUpdatedRelay.asObservable()
    }

    var allCoinUids: [String] {
        storage.favoriteCoinRecords.map(\.coinUid)
    }

    func add(coinUid: String) {
        storage.save(favoriteCoinRecord: FavoriteCoinRecord(coinUid: coinUid))
        coinUidsUpdatedRelay.accept(())
        syncSharedStorage()
    }

    func add(coinUids: [String]) {
        storage.save(favoriteCoinRecords: coinUids.map { FavoriteCoinRecord(coinUid: $0) })
        coinUidsUpdatedRelay.accept(())
        syncSharedStorage()
    }

    func removeAll() {
        storage.deleteAll()
    }

    func remove(coinUid: String) {
        storage.deleteFavoriteCoinRecord(coinUid: coinUid)
        coinUidsUpdatedRelay.accept(())
        syncSharedStorage()
    }

    func isFavorite(coinUid: String) -> Bool {
        storage.favoriteCoinRecordExists(coinUid: coinUid)
    }
}
