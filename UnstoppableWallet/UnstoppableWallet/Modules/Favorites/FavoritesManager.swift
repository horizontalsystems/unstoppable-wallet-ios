import Combine
import WidgetKit

class FavoritesManager {
    private let storage: FavoriteCoinRecordStorage
    private let sharedStorage: SharedLocalStorage

    private let coinUidsSubject = PassthroughSubject<Set<String>, Never>()

    var coinUids: Set<String> {
        didSet {
            coinUidsSubject.send(coinUids)
            syncSharedStorage()
        }
    }

    init(storage: FavoriteCoinRecordStorage, sharedStorage: SharedLocalStorage) {
        self.storage = storage
        self.sharedStorage = sharedStorage

        do {
            let records = try storage.favoriteCoinRecords()
            coinUids = Set(records.map(\.coinUid))
        } catch {
            coinUids = Set()
        }

        syncSharedStorage()
    }

    private func syncSharedStorage() {
        sharedStorage.set(value: Array(coinUids), for: AppWidgetConstants.keyFavoriteCoinUids)
        WidgetCenter.shared.reloadTimelines(ofKind: AppWidgetConstants.watchlistWidgetKind)
    }
}

extension FavoritesManager {
    var coinUidsPublisher: AnyPublisher<Set<String>, Never> {
        coinUidsSubject.eraseToAnyPublisher()
    }

    func add(coinUid: String) {
        coinUids.insert(coinUid)
        try? storage.save(favoriteCoinRecord: FavoriteCoinRecord(coinUid: coinUid))
    }

    func add(coinUids: [String]) {
        self.coinUids.formUnion(coinUids)
        try? storage.save(favoriteCoinRecords: coinUids.map { FavoriteCoinRecord(coinUid: $0) })
    }

    func removeAll() {
        coinUids = Set()
        try? storage.deleteAll()
    }

    func remove(coinUid: String) {
        coinUids.remove(coinUid)
        try? storage.deleteFavoriteCoinRecord(coinUid: coinUid)
    }

    func isFavorite(coinUid: String) -> Bool {
        coinUids.contains(coinUid)
    }
}
