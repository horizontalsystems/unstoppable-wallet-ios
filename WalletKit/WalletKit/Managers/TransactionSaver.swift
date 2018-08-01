import Foundation

class TransactionSaver {
    static let shared = TransactionSaver()

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func save(transaction: Transaction, toExistingTransaction existingTransaction: Transaction? = nil) throws {
        let realm = realmFactory.realm

        if existingTransaction != nil {
            transaction.block = existingTransaction!.block
        }

        for input in transaction.inputs {
            if let previousTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", input.previousOutputTxReversedHex.hex).last,
               previousTransaction.outputs.count > input.previousOutputIndex {
                input.previousOutput = previousTransaction.outputs[input.previousOutputIndex]
            }
        }

        try realm.write {
            realm.add(transaction, update: true)
        }
    }

}
