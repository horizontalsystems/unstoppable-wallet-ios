import Foundation

class TransactionSaver {
    static let shared = TransactionSaver()

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func save(transaction: Transaction) throws {
        let realm = realmFactory.realm

        try realm.write {
            realm.add(transaction, update: true)
        }
    }

}
