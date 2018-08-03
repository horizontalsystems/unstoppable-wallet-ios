import Foundation
import RealmSwift

@objc public enum ScriptType: Int { case unknown = 0, p2pkh, p2pk, p2sh }

public class TransactionOutput: Object {

    @objc public dynamic var value: Int64 = 0
    @objc public dynamic var lockingScript = Data()
    @objc public dynamic var index: Int = 0

    @objc public dynamic var isMine: Bool = false
    @objc public dynamic var scriptType: ScriptType = .unknown
    @objc public dynamic var keyHash: Data?

    let transactions = LinkingObjects(fromType: Transaction.self, property: "outputs")
    var transaction: Transaction {
        return self.transactions.first!
    }

    func serialized() -> Data {
        var data = Data()

        data += value
        let scriptLength = VarInt(lockingScript.count)
        data += scriptLength.serialized()
        data += lockingScript

        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> TransactionOutput {
        let transactionOutput = TransactionOutput()

        transactionOutput.value = Int64(byteStream.read(Int64.self))
        let scriptLength: VarInt = byteStream.read(VarInt.self)
        transactionOutput.lockingScript = byteStream.read(Data.self, count: Int(scriptLength.underlyingValue))

        return transactionOutput
    }


}
