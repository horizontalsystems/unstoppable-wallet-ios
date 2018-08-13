import Foundation
import RealmSwift

public class BlockHeader: Object {
    @objc dynamic var version: Int = 0
    @objc dynamic var previousBlockHeaderHash = Data()
    @objc dynamic var merkleRoot = Data()
    @objc public dynamic var timestamp: Int = 0
    @objc dynamic var bits: Int = 0
    @objc dynamic var nonce: Int = 0

    convenience init(version: Int, previousBlockHeaderReversedHex: String, merkleRootReversedHex: String, timestamp: Int, bits: Int, nonce: Int) {
        self.init()

        self.version = version
        if let data = previousBlockHeaderReversedHex.reversedData {
            previousBlockHeaderHash = data
        }
        if let data = merkleRootReversedHex.reversedData {
            merkleRoot = data
        }
        self.timestamp = timestamp
        self.bits = bits
        self.nonce = nonce
    }

    func serialized() -> Data {
        var data = Data()
        data += Int32(version)
        data += previousBlockHeaderHash
        data += merkleRoot
        data += UInt32(timestamp)
        data += UInt32(bits)
        data += UInt32(nonce)
        return data
    }

    static func deserialize(fromData data: Data) -> BlockHeader {
        return deserialize(fromByteStream: ByteStream(data))
    }

    static func deserialize(fromByteStream byteStream: ByteStream) -> BlockHeader {
        let blockHeader = BlockHeader()

        blockHeader.version = Int(byteStream.read(Int32.self))
        blockHeader.previousBlockHeaderHash = byteStream.read(Data.self, count: 32)
        blockHeader.merkleRoot = byteStream.read(Data.self, count: 32)
        blockHeader.timestamp = Int(byteStream.read(UInt32.self))
        blockHeader.bits = Int(byteStream.read(UInt32.self))
        blockHeader.nonce = Int(byteStream.read(UInt32.self))

        return blockHeader
    }

}
