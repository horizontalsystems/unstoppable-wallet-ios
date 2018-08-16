import Foundation

class TransactionHandler {
    enum HandleError: Error {
        case transactionNotFound
        case blockNotFound
    }

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory) {
        self.realmFactory = realmFactory
    }

    func handle(blockHeaderHash: Data, transactions: [Transaction]) throws {
        let realm = realmFactory.realm

        guard let block = realm.objects(Block.self).filter("reversedHeaderHashHex = %@", blockHeaderHash.reversedHex).last else {
            throw HandleError.blockNotFound
        }

        try realm.write {
            block.synced = true
            realm.add(transactions, update: true)
        }
    }

    func handle(transaction: Transaction) throws {
        let realm = realmFactory.realm

        try realm.write {
            realm.add(transaction, update: true)
        }
    }
}
