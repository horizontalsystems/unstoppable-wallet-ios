import RealmSwift
import RxSwift

class RealmStorage {
    private let realmFactory: IRealmFactory

    init(realmFactory: IRealmFactory) {
        self.realmFactory = realmFactory
    }
}

extension RealmStorage: ITransactionRecordStorage {

    func record(forHash hash: String) -> TransactionRecord? {
        return realmFactory.realm.objects(TransactionRecord.self).filter("transactionHash = %@", hash).first
    }

    var nonFilledRecords: [TransactionRecord] {
        return Array(realmFactory.realm.objects(TransactionRecord.self).filter("rate = %@", 0))
    }

    func set(rate: Double, transactionHash: String) {
        let realm = realmFactory.realm

        if let record = realm.objects(TransactionRecord.self).filter("transactionHash = %@", transactionHash).first {
            try? realm.write {
                record.rate = rate
            }
        }
    }

    func clearRates() {
        let realm = realmFactory.realm

        try? realm.write {
            for record in realm.objects(TransactionRecord.self) {
                record.rate = 0
            }
        }
    }

    func update(records: [TransactionRecord]) {
        let realm = realmFactory.realm

        try? realm.write {
            realm.add(records, update: true)
        }
    }

    func clearRecords() {
        let realm = realmFactory.realm

        try? realm.write {
            realm.delete(realm.objects(TransactionRecord.self))
        }
    }

}
