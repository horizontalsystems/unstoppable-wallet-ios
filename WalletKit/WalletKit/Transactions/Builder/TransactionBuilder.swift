import Foundation

class TransactionBuilder {
    enum BuildError: Error {
        case noPreviousTransaction
        case feeMoreThanValue
    }

    static let outputSize = 32

    let unspentOutputSelector: UnspentOutputSelector
    let unspentOutputProvider: UnspentOutputProvider
    let addressConverter: AddressConverter
    let inputSigner: InputSigner
    let scriptBuilder: ScriptBuilder
    let factory: Factory

    init(unspentOutputSelector: UnspentOutputSelector, unspentOutputProvider: UnspentOutputProvider, addressConverter: AddressConverter, inputSigner: InputSigner, scriptBuilder: ScriptBuilder, factory: Factory) {
        self.unspentOutputSelector = unspentOutputSelector
        self.unspentOutputProvider = unspentOutputProvider
        self.addressConverter = addressConverter
        self.inputSigner = inputSigner
        self.scriptBuilder = scriptBuilder
        self.factory = factory
    }

    func buildTransaction(value: Int, feeRate: Int, type: ScriptType = .p2pkh, changePubKey: PublicKey, toAddress: String) throws -> Transaction {
        let unspentOutputs = try unspentOutputSelector.select(value: value, outputs: unspentOutputProvider.allUnspentOutputs())

        let toKeyHash = try addressConverter.convert(address: toAddress)
        // Build transaction
        let transaction = factory.transaction(version: 1, inputs: [], outputs: [], lockTime: 0)

        // Add inputs without unlocking scripts
        for output in unspentOutputs {
            try addInputToTransaction(transaction: transaction, fromUnspentOutput: output)
        }

        // Add :to output
        try addOutputToTransaction(transaction: transaction, address: toAddress, keyHash: toKeyHash, value: 0, scriptType: type)

        // Calculate fee and add :change output if needed
        let fee = calculateFee(transaction: transaction, feeRate: feeRate)
        guard fee < value else {
            throw BuildError.feeMoreThanValue
        }
        let toValue = value - fee
        let totalInputValue = unspentOutputs.reduce(0, {$0 + $1.value})

        transaction.outputs[0].value = toValue
        if totalInputValue > value + feePerOutput(feeRate: feeRate) {
            try addOutputToTransaction(transaction: transaction, address: changePubKey.address, pubKey: changePubKey, keyHash: changePubKey.keyHash, value: totalInputValue - value, scriptType: type)
        }

        // Sign inputs
        for i in 0..<transaction.inputs.count {
            let sigScriptData = try inputSigner.sigScriptData(transaction: transaction, index: i)
            transaction.inputs[i].signatureScript = scriptBuilder.unlockingScript(params: sigScriptData)
        }

        transaction.status = .new
        transaction.isMine = true
        transaction.reversedHashHex = Crypto.sha256sha256(transaction.serialized()).reversedHex
        return transaction
    }

    private func feePerOutput(feeRate: Int) -> Int {
        return feeRate * TransactionBuilder.outputSize
    }

    private func calculateFee(transaction: Transaction, feeRate: Int) -> Int {
        var size = transaction.serialized().count

        // Add estimated signaturesScript sizes
        size += transaction.inputs.count * 108 // 75(Signature size) + 33(Public Key size)
        return size * feeRate
    }

    private func addInputToTransaction(transaction: Transaction, fromUnspentOutput output: TransactionOutput) throws {
        guard let previousTransaction = output.transaction else {
            throw BuildError.noPreviousTransaction
        }

        let input = factory.transactionInput(withPreviousOutputTxReversedHex: previousTransaction.reversedHashHex, previousOutputIndex: output.index, script: Data(), sequence: 0)
        input.previousOutput = output
        transaction.inputs.append(input)
    }

    private func addOutputToTransaction(transaction: Transaction, address: String, pubKey: PublicKey? = nil, keyHash: Data, value: Int, scriptType: ScriptType) throws {
        let script = try scriptBuilder.lockingScript(type: scriptType, params: [keyHash])
        let output = try factory.transactionOutput(withValue: value, index: transaction.outputs.count, lockingScript: script, type: scriptType, address: address, keyHash: keyHash, publicKey: pubKey)
        transaction.outputs.append(output)
    }

}
