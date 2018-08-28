import Foundation

class Factory {

    func block(withHeader header: BlockHeader, previousBlock: Block) -> Block {
        return Block(withHeader: header, previousBlock: previousBlock)
    }

    func block(withHeader header: BlockHeader, height: Int) -> Block {
        return Block(withHeader: header, height: height)
    }

    func block(withHeaderHash headerHash: Data, height: Int) -> Block {
        return Block(withHeaderHash: headerHash, height: height)
    }

    func transaction(version: Int, inputs: [TransactionInput], outputs: [TransactionOutput], lockTime: Int) -> Transaction {
        return Transaction(version: version, inputs: inputs, outputs: outputs, lockTime: lockTime)
    }

    func transactionInput(withPreviousOutputTxReversedHex previousOutputTxReversedHex: String, previousOutputIndex: Int, script: Data, sequence: Int) -> TransactionInput {
        return TransactionInput(withPreviousOutputTxReversedHex: previousOutputTxReversedHex, previousOutputIndex: previousOutputIndex, script: script, sequence: sequence)
    }

    func transactionOutput(withValue value: Int, index: Int, lockingScript script: Data = Data(), type: ScriptType = .unknown, address: String? = nil, keyHash: Data? = nil, publicKey: PublicKey? = nil) throws -> TransactionOutput {
        return TransactionOutput(withValue: value, index: index, lockingScript: script, type: type, address: address, keyHash: keyHash, publicKey: publicKey)
    }

    func publicKey(withIndex index: Int, external: Bool, hdPublicKey: HDPublicKey) -> PublicKey {
        return PublicKey(withIndex: index, external: external, hdPublicKey: hdPublicKey)
    }

}
