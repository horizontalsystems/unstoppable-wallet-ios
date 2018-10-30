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
