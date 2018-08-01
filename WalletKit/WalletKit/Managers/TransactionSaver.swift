import Foundation

class TransactionSaver {
    static let shared = TransactionSaver()

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func create(transaction: Transaction) throws {
        let realm = realmFactory.realm
        setPreviousOutPoints(transaction: transaction)

        try realm.write {
            realm.add(transaction, update: true)
        }
    }

    func update(transaction existingTransaction: Transaction, withContentsOfTransaction transaction: Transaction) throws {
        let realm = realmFactory.realm
        setPreviousOutPoints(transaction: transaction)

        try realm.write {
            existingTransaction.version = transaction.version
            existingTransaction.lockTime = transaction.lockTime

            for input in transaction.inputs {
                existingTransaction.inputs.append(input)
            }

            for output in transaction.outputs {
                existingTransaction.outputs.append(output)
            }
        }
    }

    private func setPreviousOutPoints(transaction: Transaction) {
        let realm = realmFactory.realm

        for input in transaction.inputs {
            if let previousTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", input.previousOutputTxReversedHex.hex).last,
               previousTransaction.outputs.count > input.previousOutputIndex {
                input.previousOutput = previousTransaction.outputs[input.previousOutputIndex]
            }
        }
    }

}
