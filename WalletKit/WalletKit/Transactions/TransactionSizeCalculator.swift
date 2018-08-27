import Foundation

class TransactionSizeCalculator {
    static let scriptSigLength = 73 + 1
    static let p2pkhLength = 33 + 1
    static let p2shLength = 20 + 1

    func transactionSize() -> Int {
        return 4 + 1 + 1 + 4 // version + inputCount + outputCount + lockTime
    }

    func outputSize(type: ScriptType) -> Int {
        let outputTxSize: Int = 8 + 1 + Int(type.size) // spentValue + scriptLength + script
        return outputTxSize
    }

    func  inputSize(type: ScriptType) -> Int {
        let keyLength: Int
        switch type {
        case .p2pkh: keyLength = TransactionSizeCalculator.p2pkhLength
        case .p2sh: keyLength = TransactionSizeCalculator.p2shLength
        default: keyLength = 0
        }
        let inputTxSize: Int = 32 + 4 + 1 + TransactionSizeCalculator.scriptSigLength + keyLength + 4 // PreviousOutputHex + InputIndex + sigLength + sigScript + sequence
        return inputTxSize
    }

}
