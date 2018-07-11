import Foundation
import RxSwift
import RealmSwift
import RxRealm

public class DatabaseManager: IDatabaseManager {
    private let realm = try! Realm()

    public init() {
    }

//    func getBitcoinUnspentOutputs() -> Observable<DatabaseChangeSet<BitcoinUnspentOutput>> {
//        return Observable.arrayWithChangeset(from: realm.objects(BitcoinUnspentOutput.self))
//                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
//    }
//
//    func getBitcoinCashUnspentOutputs() -> Observable<DatabaseChangeSet<BitcoinCashUnspentOutput>> {
//        return Observable.arrayWithChangeset(from: realm.objects(BitcoinCashUnspentOutput.self))
//                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
//    }

    public func getBalances() -> Observable<DatabaseChangeSet<Balance>> {
        return Observable.arrayWithChangeset(from: realm.objects(Balance.self))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

    public func getExchangeRates() -> Observable<DatabaseChangeSet<ExchangeRate>> {
        return Observable.arrayWithChangeset(from: realm.objects(ExchangeRate.self))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

    public func getTransactionRecords() -> Observable<DatabaseChangeSet<TransactionRecord>> {
        return Observable.arrayWithChangeset(from: realm.objects(TransactionRecord.self).sorted(byKeyPath: "blockHeight", ascending: false))
                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
    }

//    func getBlockchainInfos() -> Observable<DatabaseChangeSet<BlockchainInfo>> {
//        return Observable.arrayWithChangeset(from: realm.objects(BlockchainInfo.self))
//                .map { DatabaseChangeSet(array: $0, changeSet: $1.map { CollectionChangeSet(withRealmChangeset: $0) }) }
//    }

}
