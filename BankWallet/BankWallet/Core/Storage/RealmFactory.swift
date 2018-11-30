import RealmSwift

class RealmFactory {
    private let configuration: Realm.Configuration

    init() {
        let realmFileName = "bank.realm"
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

        configuration = Realm.Configuration(
                fileURL: documentsUrl?.appendingPathComponent(realmFileName),
                schemaVersion: 1,
                migrationBlock: { migration, oldSchemaVersion in

                    if (oldSchemaVersion < 1) {
                        migration.enumerateObjects(ofType: TransactionRecord.className()) { oldObject, newObject in
                            let oldTimestamp = oldObject!["timestamp"] as! Int
                            newObject!["timestamp"] = Double(oldTimestamp)
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
