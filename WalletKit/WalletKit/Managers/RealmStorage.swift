import Foundation
import RxSwift
import RealmSwift
import RxRealm

public class RealmStorage: IStorage {
    public static let shared = RealmStorage()

    private let factory: RealmFactory

    init(factory: RealmFactory = .shared) {
        self.factory = factory
    }

    public func getBalances() -> Observable<DatabaseChangeSet<Balance>> {
        return Observable.arrayWithChangeset(from: factory.realm.objects(Balance.self))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

    public func getExchangeRates() -> Observable<DatabaseChangeSet<ExchangeRate>> {
        return Observable.arrayWithChangeset(from: factory.realm.objects(ExchangeRate.self))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

    public func getTransactionRecords() -> Observable<DatabaseChangeSet<TransactionRecord>> {
        return Observable.arrayWithChangeset(from: factory.realm.objects(TransactionRecord.self).sorted(byKeyPath: "blockHeight", ascending: false))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

}
