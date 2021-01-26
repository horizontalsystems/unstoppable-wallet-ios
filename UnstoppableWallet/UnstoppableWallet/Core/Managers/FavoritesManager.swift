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

    public func add(coinCode: String, coinTitle: String, coinType: CoinType?) {
        storage.save(coinCode: coinCode, coinTitle: coinTitle, coinType: coinType)

        dataUpdatedRelay.accept(())
    }

    public func remove(coinCode: String, coinType: CoinType?) {
        storage.deleteFavoriteCoinRecord(coinCode: coinCode, coinType: coinType)

        dataUpdatedRelay.accept(())
    }

    public func isFavorite(coinCode: String, coinType: CoinType?) -> Bool {
        return storage.inFavorites(coinCode: coinCode, coinType: coinType)
    }

}
