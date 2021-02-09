import RxSwift
import RxCocoa

class FavoritesManager {
    private let storage: IFavoriteCoinRecordStorage

    private let dataUpdatedRelay = PublishRelay<()>()

    init(storage: IFavoriteCoinRecordStorage) {
        self.storage = storage
    }

}

extension FavoritesManager: IFavoritesManager {

    public var dataUpdatedObservable: Observable<()> {
        dataUpdatedRelay.asObservable()
    }

    public var all: [FavoriteCoinRecord] {
        storage.favoriteCoinRecords
    }

    public func add(coinCode: String) {
        storage.save(coinCode: coinCode)

        dataUpdatedRelay.accept(())
    }

    public func remove(coinCode: String) {
        storage.deleteFavoriteCoinRecord(coinCode: coinCode)

        dataUpdatedRelay.accept(())
    }

    public func isFavorite(coinCode: String) -> Bool {
        return storage.inFavorites(coinCode: coinCode)
    }

}
