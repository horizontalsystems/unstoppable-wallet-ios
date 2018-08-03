import Foundation
import RealmSwift

public class TransactionInput: Object {
    @objc public dynamic var previousOutputTxReversedHex = Data()
    @objc public dynamic var previousOutputIndex: Int = 0
    @objc public dynamic var signatureScript = Data()
    @objc public dynamic var sequence: Int = 0
    @objc public dynamic var previousOutput: TransactionOutput? = nil
    @objc public dynamic var publicKey: Data?

    let transactions = LinkingObjects(fromType: Transaction.self, property: "inputs")
    var transaction: Transaction {
        return self.transactions.first!
    }

    func serialized() -> Data {
        var data = Data()
        if let output = previousOutput {
            data += output.transaction.reversedHashHex.reversedData!
            data += UInt32(output.index)
        } else {
            data += previousOutputTxReversedHex.reversed()
            data += UInt32(previousOutputIndex)
        }

        let scriptLength = VarInt(signatureScript.count)
        data += scriptLength.serialized()
        data += signatureScript
        data += UInt32(sequence)

        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> TransactionInput {
        let transactionInput = TransactionInput()

        transactionInput.previousOutputTxReversedHex = Data(byteStream.read(Data.self, count: 32).reversed())
        transactionInput.previousOutputIndex = Int(byteStream.read(UInt32.self))

        let scriptLength: VarInt = byteStream.read(VarInt.self)

        transactionInput.signatureScript = byteStream.read(Data.self, count: Int(scriptLength.underlyingValue))
        transactionInput.sequence = Int(byteStream.read(UInt32.self))

        return transactionInput
    }

}
