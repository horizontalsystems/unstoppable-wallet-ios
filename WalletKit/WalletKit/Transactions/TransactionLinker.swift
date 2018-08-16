import Foundation
import RealmSwift

class TransactionLinker {
    func handle(transaction: Transaction, realm: Realm, pubKeys: Results<PublicKey>) {
        linkInputs(transaction: transaction, realm: realm)
        linkOutputs(transaction: transaction, realm: realm, pubKeys: pubKeys)
    }

    private func linkInputs(transaction: Transaction, realm: Realm) {
        for input in transaction.inputs {
            if let previousTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", input.previousOutputTxReversedHex).last,
               previousTransaction.outputs.count > input.previousOutputIndex {
                input.previousOutput = previousTransaction.outputs[input.previousOutputIndex]

                if input.previousOutput!.publicKey != nil {
                    transaction.isMine = true
                }
            }
        }
    }

    private func linkOutputs(transaction: Transaction, realm: Realm, pubKeys: Results<PublicKey>) {
        for output in transaction.outputs {
            let pubKey = pubKeys.filter({ $0.keyHash == output.keyHash }).first

            if pubKey != nil {
                transaction.isMine = true
                output.publicKey = pubKey
            }

            if let input = realm.objects(TransactionInput.self)
                    .filter("previousOutputTxReversedHex = %@ AND previousOutputIndex = %@", transaction.reversedHashHex, output.index).last {
                input.previousOutput = output
                if pubKey != nil {
                    if let nextTransaction = input.transaction {
                        nextTransaction.isMine = true
                    }
                }
            }
        }
    }

}
