import Foundation

public struct BlockHeaderItem {
    /// Block version information (note, this is signed)
    public let version: Int32
    /// The hash value of the previous block this particular block references
    public let prevBlock: Data
    /// The reference to a Merkle tree collection which is a hash of all transactions related to this block
    public let merkleRoot: Data
    /// A Unix timestamp recording when this block was created (Currently limited to dates before the year 2106!)
    public let timestamp: UInt32
    /// The calculated difficulty target being used for this block
    public let bits: UInt32
    /// The nonce used to generate this block… to allow variations of the header and compute different hashes
    public let nonce: UInt32

    public func serialized() -> Data {
        var data = Data()
        data += version
        data += prevBlock
        data += merkleRoot
        data += timestamp
        data += bits
        data += nonce
        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> BlockHeaderItem {
        let version = byteStream.read(Int32.self)
        let prevBlock = byteStream.read(Data.self, count: 32)
        let merkleRoot = byteStream.read(Data.self, count: 32)
        let timestamp = byteStream.read(UInt32.self)
        let bits = byteStream.read(UInt32.self)
        let nonce = byteStream.read(UInt32.self)
        return BlockHeaderItem(version: version, prevBlock: prevBlock, merkleRoot: merkleRoot, timestamp: timestamp, bits: bits, nonce: nonce)
    }

}
