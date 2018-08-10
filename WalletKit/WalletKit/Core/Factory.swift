import Foundation

class Factory {

    func block(withHeader header: BlockHeader, previousBlock: Block) -> Block {
        return Block(withHeader: header, previousBlock: previousBlock)
    }

    func block(withHeader header: BlockHeader, height: Int) -> Block {
        return Block(withHeader: header, height: height)
    }

    func transaction(version: Int, inputs: [TransactionInput], outputs: [TransactionOutput], lockTime: Int) -> Transaction {
        return Transaction(version: version, inputs: inputs, outputs: outputs, lockTime: lockTime)
    }

    func transactionInput(withPreviousOutput output: TransactionOutput, script: Data, sequence: Int) -> TransactionInput {
        return TransactionInput(withPreviousOutput: output, script: script, sequence: sequence)
    }

    func transactionOutput(withValue value: Int, withLockingScript script: Data, withIndex index: Int, type: ScriptType, keyHash: Data) throws -> TransactionOutput {
        return TransactionOutput(withValue: value, withLockingScript: script, withIndex: index, type: type, keyHash: keyHash)
    }

}
