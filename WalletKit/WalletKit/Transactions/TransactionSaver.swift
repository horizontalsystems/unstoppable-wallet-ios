import Foundation

class TransactionSaver {
    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory) {
        self.realmFactory = realmFactory
    }

    func save(transaction: Transaction) throws {
        let realm = realmFactory.realm

        try realm.write {
            realm.add(transaction, update: true)
        }
    }

}
