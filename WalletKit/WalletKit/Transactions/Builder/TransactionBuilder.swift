import Foundation

class TransactionBuilder {
    enum BuildError: Error {
        case insufficientFunds
    }

    static let shared = TransactionBuilder()
    static let outputSize = 120

    let unspentOutputsManager: UnspentOutputsManager
    let realmFactory: RealmFactory
    let inputSigner: InputSigner
    let txFactory: TransactionFactory
    let txOutputFactory: TransactionOutputFactory
    let txInputFactory: TransactionInputFactory

    init(realmFactory: RealmFactory = .shared, unspentOutputSelector: UnspentOutputsManager = .shared, inputSigner: InputSigner = .shared,
         txFactory: TransactionFactory = .shared, txInputFactory: TransactionInputFactory = .shared, txOutputFactory: TransactionOutputFactory = .shared) {
        self.realmFactory = realmFactory
        self.unspentOutputsManager = unspentOutputSelector
        self.inputSigner = inputSigner
        self.txFactory = txFactory
        self.txInputFactory = txInputFactory
        self.txOutputFactory = txOutputFactory
    }

    func buildTransaction(value: Int, feeRate: Int, type: ScriptType = .p2pkh, changeAddress: Address, toAddress: Address) throws -> Transaction {
        let unspentOutputs = try unspentOutputsManager.select(value: value)

        // Build transaction
        let transaction = txFactory.transaction(version: 1, inputs: [], outputs: [])

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
        guard toValue <= totalInputValue else {
            throw BuildError.insufficientFunds
        }

        transaction.outputs[0].value = toValue
        if totalInputValue > value + feePerOutput(feeRate: feeRate) {
            try addOutputToTransaction(transaction: transaction, forAddress: changeAddress, withValue: totalInputValue - value, scriptType: type)
        }

        // Sign inputs
        for i in 0..<transaction.inputs.count {
            transaction.inputs[i].signatureScript = try inputSigner.signature(input: transaction.inputs[i], transaction: transaction, index: i)
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
        let input = txInputFactory.transactionInput(withPreviousOutput: output, script: Data(), sequence: 0)
        transaction.inputs.append(input)
    }

    private func addOutputToTransaction(transaction: Transaction, forAddress address: Address, withValue value: Int, scriptType type: ScriptType) throws {
        let output = try txOutputFactory.transactionOutput(withValue: value, withIndex: transaction.outputs.count, forAddress: address, type: type)
        transaction.outputs.append(output)
    }

}
