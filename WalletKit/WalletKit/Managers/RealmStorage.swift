import Foundation
import RxSwift
import RealmSwift
import RxRealm

class RealmStorage: IStorage {
    static let shared = RealmStorage()

    let factory: RealmFactory

    init(factory: RealmFactory = .shared) {
        self.factory = factory
    }

    func getFirstBlockInChain() -> Block? {
        return factory.realm.objects(Block.self).filter("previousBlock != nil").sorted(byKeyPath: "height").first
    }

    func getLastBlockInChain(afterBlock: Block) -> Block? {
        return factory.realm.objects(Block.self).filter("previousBlock != nil AND height > %@", afterBlock.height).sorted(byKeyPath: "height").last
    }

    func getBlockInChain(withHeight height: Int) -> Block? {
        return factory.realm.objects(Block.self).filter("previousBlock != nil AND height = %@", height).first
    }

    func getBalances() -> Observable<DatabaseChangeSet<Balance>> {
        return Observable.arrayWithChangeset(from: factory.realm.objects(Balance.self))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

    func getExchangeRates() -> Observable<DatabaseChangeSet<ExchangeRate>> {
        return Observable.arrayWithChangeset(from: factory.realm.objects(ExchangeRate.self))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

    func getTransactionRecords() -> Observable<DatabaseChangeSet<TransactionRecord>> {
        return Observable.arrayWithChangeset(from: factory.realm.objects(TransactionRecord.self).sorted(byKeyPath: "blockHeight", ascending: false))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

}
