import Foundation

class TransactionFactory {

    func transaction(version: Int, inputs: [TransactionInput], outputs: [TransactionOutput], lockTime: Int = 0) -> Transaction {
        let transaction = Transaction()
        transaction.version = version

        inputs.forEach { transaction.inputs.append($0) }
        outputs.forEach { transaction.outputs.append($0) }

        transaction.lockTime = lockTime
        transaction.reversedHashHex = Crypto.sha256sha256(transaction.serialized()).reversedHex

        return transaction
    }

    func transaction(withReversedHashHex hash: String) -> Transaction {
        let transaction = Transaction()
        transaction.reversedHashHex = hash

        return transaction
    }

}
