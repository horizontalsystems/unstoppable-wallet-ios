import Foundation
import RealmSwift

public class TransactionInput: Object {
    @objc dynamic var previousOutputTxReversedHex = ""
    @objc dynamic var previousOutputIndex: Int = 0
    @objc dynamic var signatureScript = Data()
    @objc dynamic var sequence: Int = 0
    @objc public dynamic var previousOutput: TransactionOutput? = nil
    @objc dynamic var keyHash: Data?
    @objc dynamic var address: String?

    let transactions = LinkingObjects(fromType: Transaction.self, property: "inputs")
    var transaction: Transaction? {
        return self.transactions.first
    }

    convenience init(withPreviousOutputTxReversedHex previousOutputTxReversedHex: String, previousOutputIndex: Int, script: Data, sequence: Int) {
        self.init()

        self.previousOutputTxReversedHex = previousOutputTxReversedHex
        self.previousOutputIndex = previousOutputIndex
        signatureScript = script
        self.sequence = sequence
    }

    func serialized() -> Data {
        var data = Data()
        data += previousOutputTxReversedHex.reversedData ?? Data()
        data += UInt32(previousOutputIndex)

        let scriptLength = VarInt(signatureScript.count)
        data += scriptLength.serialized()
        data += signatureScript
        data += UInt32(sequence)

        return data
    }

    func serializedForSignature(forCurrentInputSignature: Bool) throws -> Data {
        var data = Data()

        guard let output = previousOutput else {
            throw SerializationError.noPreviousOutput
        }

        guard let previousTransactionData = output.transaction?.reversedHashHex.reversedData else {
            throw SerializationError.noPreviousTransaction
        }
        data += previousTransactionData
        data += UInt32(output.index)

        if forCurrentInputSignature {
            let scriptLength = VarInt(output.lockingScript.count)
            data += scriptLength.serialized()
            data += output.lockingScript
        } else {
            data += VarInt(0).serialized()
        }

        data += UInt32(sequence)

        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> TransactionInput {
        let transactionInput = TransactionInput()

        transactionInput.previousOutputTxReversedHex = Data(byteStream.read(Data.self, count: 32).reversed()).hex
        transactionInput.previousOutputIndex = Int(byteStream.read(UInt32.self))

        let scriptLength: VarInt = byteStream.read(VarInt.self)

        transactionInput.signatureScript = byteStream.read(Data.self, count: Int(scriptLength.underlyingValue))
        transactionInput.sequence = Int(byteStream.read(UInt32.self))

        return transactionInput
    }

}

enum SerializationError: Error {
    case noPreviousOutput
    case noPreviousTransaction
}
