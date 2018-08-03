import Foundation

class TransactionLinker {
    static let shared = TransactionLinker()

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func linkOutpoints(transaction: Transaction) throws {
        let realm = realmFactory.realm

        for input in transaction.inputs {
            if let previousTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", input.previousOutputTxReversedHex.hex).last,
               previousTransaction.outputs.count > input.previousOutputIndex {
                try realm.write {
                    input.previousOutput = previousTransaction.outputs[input.previousOutputIndex]
                }

            }
        }

        for output in transaction.outputs {
            if let input = realm.objects(TransactionInput.self)
                    .filter("previousOutputTxReversedHex = %@ AND previousOutputIndex = %@", Data(hex: transaction.reversedHashHex)!, output.index).last {
                try realm.write {
                    input.previousOutput = output
                }
            }
        }
    }

}
