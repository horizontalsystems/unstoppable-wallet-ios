import Foundation

class TransactionBuilder {
    static let outputSize = 32

    let unspentOutputsManager: UnspentOutputsManager
    let inputSigner: InputSigner
    let scriptBuilder: ScriptBuilder
    let factory: Factory

    init(unspentOutputsManager: UnspentOutputsManager, inputSigner: InputSigner, scriptBuilder: ScriptBuilder, factory: Factory) {
        self.unspentOutputsManager = unspentOutputsManager
        self.inputSigner = inputSigner
        self.scriptBuilder = scriptBuilder
        self.factory = factory
    }

    func buildTransaction(value: Int, feeRate: Int, type: ScriptType = .p2pkh, changeAddress: Address, toAddress: Address) throws -> Transaction {
        let unspentOutputs = try unspentOutputsManager.select(value: value)

        // Build transaction
        let transaction = factory.transaction(version: 1, inputs: [], outputs: [], lockTime: 0)

        // Add inputs without unlocking scripts
        for output in unspentOutputs {
            addInputToTransaction(transaction: transaction, fromUnspentOutput: output)
        }

        // Add :to output
        try addOutputToTransaction(transaction: transaction, forAddress: toAddress, withValue: 0, scriptType: type)

        // Calculate fee and add :change output if needed
        let fee = calculateFee(transaction: transaction, feeRate: feeRate)
        let toValue = value - fee
        let totalInputValue = unspentOutputs.reduce(0, {$0 + $1.value})

        transaction.outputs[0].value = toValue
        if totalInputValue > value + feePerOutput(feeRate: feeRate) {
            try addOutputToTransaction(transaction: transaction, forAddress: changeAddress, withValue: totalInputValue - value, scriptType: type)
        }

        // Sign inputs
        for i in 0..<transaction.inputs.count {
            let sigScriptData = try inputSigner.sigScriptData(input: transaction.inputs[i], transaction: transaction, index: i)
            transaction.inputs[i].signatureScript = scriptBuilder.unlockingScript(params: sigScriptData)
        }

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

    private func addInputToTransaction(transaction: Transaction, fromUnspentOutput output: TransactionOutput) {
        let input = factory.transactionInput(withPreviousOutput: output, script: Data(), sequence: 0)
        transaction.inputs.append(input)
    }

    private func addOutputToTransaction(transaction: Transaction, forAddress address: Address, withValue value: Int, scriptType type: ScriptType) throws {
        let script = try scriptBuilder.lockingScript(type: type, params: [address.publicKeyHash])
        let output = try factory.transactionOutput(withValue: value, withLockingScript: script, withIndex: transaction.outputs.count, type: type, keyHash: address.publicKeyHash)
        transaction.outputs.append(output)
    }

}
