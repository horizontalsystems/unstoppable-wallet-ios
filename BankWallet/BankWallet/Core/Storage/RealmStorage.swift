import RealmSwift

class RealmStorage {
    private let realmFactory: IRealmFactory

    init(realmFactory: IRealmFactory) {
        self.realmFactory = realmFactory
    }
}

extension RealmStorage: IRateStorage {

    func rate(forCoin coin: Coin, currencyCode: String) -> Rate? {
        return realmFactory.realm.objects(Rate.self).filter("coin = %@ AND currencyCode = %@", coin, currencyCode).first
    }

    func save(value: Double, coin: Coin, currencyCode: String) {
        let realm = realmFactory.realm

        try? realm.write {
            if let rate = realm.objects(Rate.self).filter("coin = %@ AND currencyCode = %@", coin, currencyCode).first {
                rate.value = value
                rate.timestamp = Date().timeIntervalSince1970
            } else {
                let rate = Rate()
                rate.coin = coin
                rate.currencyCode = currencyCode
                rate.value = value
                rate.timestamp = Date().timeIntervalSince1970

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

}
