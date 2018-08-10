import Foundation
import RealmSwift

class TransactionLinker {
    let realmFactory: RealmFactory
    let addresses: Results<Address>

    init(realmFactory: RealmFactory) {
        self.realmFactory = realmFactory
        addresses = realmFactory.realm.objects(Address.self)
    }

    func handle(transaction: Transaction) throws {
        let realm = realmFactory.realm

        try realm.write {
            for input in transaction.inputs {
                if let previousTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", input.previousOutputTxReversedHex.hex).last,
                   previousTransaction.outputs.count > input.previousOutputIndex {
                    input.previousOutput = previousTransaction.outputs[input.previousOutputIndex]

                    if input.previousOutput!.isMine {
                        transaction.isMine = true
                    }
                }
            }

            for output in transaction.outputs {
                let isMine = addresses.contains(where: { $0.publicKeyHash == output.keyHash })

                if isMine {
                    transaction.isMine = true
                    output.isMine = true
                }

                if let input = realm.objects(TransactionInput.self)
                        .filter("previousOutputTxReversedHex = %@ AND previousOutputIndex = %@", Data(hex: transaction.reversedHashHex)!, output.index).last {
                    input.previousOutput = output
                    if isMine {
                        input.transaction.isMine = true
                    }
                }
            }
        }
    }

}
