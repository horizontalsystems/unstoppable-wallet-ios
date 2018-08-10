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

    func transactionOutput(withValue value: Int, withLockingScript script: Data, withIndex index: Int) -> TransactionOutput {
        let transactionOutput = TransactionOutput()
        transactionOutput.value = value
        transactionOutput.lockingScript = script
        transactionOutput.index = index

        return transactionOutput
    }

    func transactionOutput(withValue value: Int, withLockingScript script: Data, withIndex index: Int, type: ScriptType, keyHash: Data) throws -> TransactionOutput {
        let transactionOutput = TransactionOutput()
        transactionOutput.value = value
        transactionOutput.lockingScript = script
        transactionOutput.index = index
        transactionOutput.scriptType = type
        transactionOutput.keyHash = keyHash

        return transactionOutput
    }

}
