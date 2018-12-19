import RealmSwift

class RealmFactory {
    private let configuration: Realm.Configuration

    init() {
        let realmFileName = "bank.realm"
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

        let schemaVersion: UInt64 = 2
        configuration = Realm.Configuration(
                fileURL: documentsUrl?.appendingPathComponent(realmFileName),
                schemaVersion: schemaVersion,
                migrationBlock: { migration, oldSchemaVersion in

                    if (oldSchemaVersion < 1) {
                        migration.enumerateObjects(ofType: TransactionRecord.className()) { oldObject, newObject in
                            let oldTimestamp = oldObject!["timestamp"] as! Int
                            newObject!["timestamp"] = Double(oldTimestamp)
                        }
                    }
                    if oldSchemaVersion < 2 {
                        migration.enumerateObjects(ofType: TransactionRecord.className()) { oldObject, newObject in
                            let oldCoin = oldObject!["coin"] as! CoinCode
                            newObject!["coinCode"] = oldCoin
                        }
                        migration.enumerateObjects(ofType: Rate.className()) { oldObject, newObject in
                            let oldCoin = oldObject!["coin"] as! CoinCode
                            newObject!["coinCode"] = oldCoin
                        }
                    }

                },
                objectTypes: [
                    TransactionRecord.self,
                    TransactionAddress.self,
                    Rate.self
                ]
        )
    }

}

extension RealmFactory: IRealmFactory {

    var realm: Realm {
        return try! Realm(configuration: configuration)
    }

}
