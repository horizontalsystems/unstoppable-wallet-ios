import Foundation

class TransactionOutputFactory {
    static let shared = TransactionOutputFactory()
    let scriptBuilder: ScriptBuilder

    init(scriptBuilder: ScriptBuilder = .shared) {
        self.scriptBuilder = scriptBuilder
    }

    func transactionOutput(withValue value: Int, withLockingScript script: Data, withIndex index: Int) -> TransactionOutput {
        let transactionOutput = TransactionOutput()
        transactionOutput.value = value
        transactionOutput.lockingScript = script
        transactionOutput.index = index

        return transactionOutput
    }

    func transactionOutput(withValue value: Int, withIndex index: Int, forAddress address: Address, type: ScriptType) throws -> TransactionOutput {
        let script = try scriptBuilder.lockingScript(type: type, params: [address.publicKeyHash])

        let transactionOutput = TransactionOutput()
        transactionOutput.value = value
        transactionOutput.lockingScript = script
        transactionOutput.index = index
        transactionOutput.scriptType = type
        transactionOutput.keyHash = address.publicKeyHash

        return transactionOutput
    }

}
