import RealmSwift

class RealmStorage {
    private let realmFactory: IRealmFactory

    init(realmFactory: IRealmFactory) {
        self.realmFactory = realmFactory
    }
}

extension RealmStorage: IRateStorage {

    func rate(forCoin coinCode: CoinCode, currencyCode: String) -> Rate? {
        return realmFactory.realm.objects(Rate.self).filter("coinCode = %@ AND currencyCode = %@", coinCode, currencyCode).first
    }

    func save(latestRate: LatestRate, coinCode: CoinCode, currencyCode: String) {
        let realm = realmFactory.realm

        try? realm.write {
            if let rate = realm.objects(Rate.self).filter("coinCode = %@ AND currencyCode = %@", coinCode, currencyCode).first {
                rate.value = latestRate.value
                rate.timestamp = latestRate.timestamp
            } else {
                let rate = Rate()
                rate.coinCode = coinCode
                rate.currencyCode = currencyCode
                rate.value = latestRate.value
                rate.timestamp = latestRate.timestamp

                realm.add(rate)
            }
        }
    }

    func clear() {
        let realm = realmFactory.realm

        try? realm.write {
            realm.delete(realm.objects(Rate.self))
        }
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
