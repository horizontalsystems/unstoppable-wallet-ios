import Foundation

class TransactionOutputFactory {
    static let shared = TransactionOutputFactory()

    func transactionOutput(withValue value: Int, withLockingScript script: Data, withIndex index: Int) -> TransactionOutput {
        let transactionOutput = TransactionOutput()
        transactionOutput.value = value
        transactionOutput.lockingScript = script
        transactionOutput.index = index

        return transactionOutput
    }

}
