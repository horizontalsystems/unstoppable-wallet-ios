import Foundation
import RealmSwift

@objc public enum ScriptType: Int {
    case unknown = 0, p2pkh, p2pk, p2sh

    var size: Int {
        switch self {
            case .p2pk: return 35
            case .p2pkh: return 25
            default: return 0
        }
    }

    var keyLength: UInt8 {
        switch self {
            case .p2pk: return 0x03
            case .p2pkh: return 0x14
            case .p2sh: return 0x14
            default: return 0
        }
    }

}

public class TransactionOutput: Object {

    @objc public dynamic var value: Int = 0
    @objc public dynamic var lockingScript = Data()
    @objc public dynamic var index: Int = 0

    @objc public dynamic var isMine: Bool = false
    @objc public dynamic var scriptType: ScriptType = .unknown
    @objc public dynamic var keyHash: Data?

    let transactions = LinkingObjects(fromType: Transaction.self, property: "outputs")
    var transaction: Transaction {
        return self.transactions.first!
    }

    let inputs = LinkingObjects(fromType: TransactionInput.self, property: "previousOutput")

    convenience init(withValue value: Int, withLockingScript script: Data, withIndex index: Int) {
        self.init()

        self.value = value
        self.lockingScript = script
        self.index = index
    }

    convenience init(withValue value: Int, withLockingScript script: Data, withIndex index: Int, type: ScriptType, keyHash: Data) {
        self.init(withValue: value, withLockingScript: script, withIndex: index)

        self.scriptType = type
        self.keyHash = keyHash
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

        transactionOutput.value = Int(byteStream.read(Int64.self))
        let scriptLength: VarInt = byteStream.read(VarInt.self)
        transactionOutput.lockingScript = byteStream.read(Data.self, count: Int(scriptLength.underlyingValue))

        return transactionOutput
    }


}
