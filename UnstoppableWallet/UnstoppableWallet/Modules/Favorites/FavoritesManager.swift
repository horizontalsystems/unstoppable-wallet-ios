import RxSwift
import RxCocoa
import CoinKit

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

    public func add(coinType: CoinType) {
        storage.save(coinType: coinType)

        dataUpdatedRelay.accept(())
    }

    public func remove(coinType: CoinType) {
        storage.deleteFavoriteCoinRecord(coinType: coinType)

        dataUpdatedRelay.accept(())
    }

    public func isFavorite(coinType: CoinType) -> Bool {
        storage.inFavorites(coinType: coinType)
    }

}
