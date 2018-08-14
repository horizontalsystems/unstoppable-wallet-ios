import Foundation
import RealmSwift

class TransactionLinker {
    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory) {
        self.realmFactory = realmFactory
    }

    func handle(transaction: Transaction) throws {
        let realm = realmFactory.realm
        let addresses = realm.objects(Address.self)

        try realm.write {
            for input in transaction.inputs {
                if let previousTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", input.previousOutputTxReversedHex).last,
                   previousTransaction.outputs.count > input.previousOutputIndex {
                    input.previousOutput = previousTransaction.outputs[input.previousOutputIndex]

                    if input.previousOutput!.address != nil {
                        transaction.isMine = true
                    }
                }
            }

            for output in transaction.outputs {
                let address = addresses.filter({ $0.publicKeyHash == output.keyHash }).first

                if address != nil {
                    transaction.isMine = true
                    output.address = address
                }

                if let input = realm.objects(TransactionInput.self)
                        .filter("previousOutputTxReversedHex = %@ AND previousOutputIndex = %@", transaction.reversedHashHex, output.index).last {
                    input.previousOutput = output
                    if address != nil {
                        input.transaction.isMine = true
                    }
                }
            }
        }
    }

}
