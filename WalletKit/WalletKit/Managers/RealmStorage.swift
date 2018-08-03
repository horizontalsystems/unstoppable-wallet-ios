import Foundation
import RxSwift
import RealmSwift
import RxRealm

class RealmStorage: IStorage {
    static let shared = RealmStorage()

    private let factory: RealmFactory

    let nonSyncedBlocksInsertSubject = PublishSubject<Void>()
    private var nonSyncedBlocksNotificationToken: NotificationToken?

    init(factory: RealmFactory = .shared) {
        self.factory = factory

        nonSyncedBlocksNotificationToken = factory.realm.objects(Block.self).filter("synced = %@", false).observe { [weak self] changes in
            if case let .update(_, _, insertions, _) = changes, !insertions.isEmpty {
                self?.nonSyncedBlocksInsertSubject.onNext(())
            }
        }
    }

    deinit {
        nonSyncedBlocksNotificationToken?.invalidate()
    }

    func getFirstBlockInChain() -> Block? {
        return blocksInChain.first
    }

    func getLastBlockInChain() -> Block? {
        return blocksInChain.first
    }

    func getLastBlockInChain(afterBlock: Block) -> Block? {
        return blocksInChain.filter("height > %@", afterBlock.height).last
    }

    func getBlockInChain(withHeight height: Int) -> Block? {
        return blocksInChain.filter("height = %@", height).first
    }

    func getNonSyncedBlockHeaderHashes() -> [Data] {
        let blocks = factory.realm.objects(Block.self).filter("synced = %@", false).sorted(byKeyPath: "height")
        return blocks.map { $0.headerHash }
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

    private var blocksInChain: Results<Block> {
        return factory.realm.objects(Block.self).filter("previousBlock != nil").sorted(byKeyPath: "height")
    }

}
