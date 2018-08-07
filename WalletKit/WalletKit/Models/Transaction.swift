import Foundation
import RealmSwift

public class Transaction: Object {
    @objc public dynamic var reversedHashHex: String = ""
    @objc public dynamic var version: Int = 0
    @objc public dynamic var lockTime: Int = 0
    @objc public dynamic var block: Block?

    @objc public dynamic var isMine: Bool = false

    public let inputs = List<TransactionInput>()
    public let outputs = List<TransactionOutput>()

    override public class func primaryKey() -> String? {
        return "reversedHashHex"
    }

    func serialized() -> Data {
        var data = Data()

        data += UInt32(version)
        data += VarInt(inputs.count).serialized()
        data += inputs.flatMap { $0.serialized() }
        data += VarInt(outputs.count).serialized()
        data += outputs.flatMap { $0.serialized() }
        data += UInt32(lockTime)

        return data
    }

    static func deserialize(_ data: Data) -> Transaction {
        let byteStream = ByteStream(data)
        return deserialize(byteStream)
    }

    static func deserialize(_ byteStream: ByteStream) -> Transaction {
        let transaction = Transaction()

        transaction.version = Int(byteStream.read(Int32.self))

        let txInCount = byteStream.read(VarInt.self)
        for _ in 0..<Int(txInCount.underlyingValue) {
            transaction.inputs.append(TransactionInput.deserialize(byteStream))
        }

        let txOutCount = byteStream.read(VarInt.self)
        for i in 0..<Int(txOutCount.underlyingValue) {
            let output = TransactionOutput.deserialize(byteStream)
            output.index = i
            transaction.outputs.append(output)
        }

        transaction.lockTime = Int(byteStream.read(UInt32.self))
        transaction.reversedHashHex = Crypto.sha256sha256(transaction.serialized()).reversedHex

        return transaction
    }

}
