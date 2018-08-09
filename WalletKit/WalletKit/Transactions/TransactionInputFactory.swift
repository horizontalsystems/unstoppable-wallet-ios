import Foundation

class TransactionInputFactory {
    static let shared = TransactionInputFactory()

    func transactionInput(withPreviousOutput output: TransactionOutput, script: Data, sequence: Int) -> TransactionInput {
        let transactionInput = TransactionInput()
        transactionInput.previousOutputTxReversedHex = Data(hex: output.transaction.reversedHashHex)!
        transactionInput.previousOutputIndex = output.index
        transactionInput.previousOutput = output
        transactionInput.signatureScript = script
        transactionInput.sequence = sequence

        return transactionInput
    }

    func transactionInput(withPreviousOutputTxReversedHex previousOutputTxReversedHex: Data, withPreviousOutputIndex previousOutputIndex: Int, script: Data, sequence: Int) -> TransactionInput {
        let transactionInput = TransactionInput()
        transactionInput.previousOutputTxReversedHex = previousOutputTxReversedHex
        transactionInput.previousOutputIndex = previousOutputIndex
        transactionInput.signatureScript = script
        transactionInput.sequence = sequence

        return transactionInput
    }


}
