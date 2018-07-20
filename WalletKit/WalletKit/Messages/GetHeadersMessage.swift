import Foundation

struct GetHeadersMessage {
    /// the protocol version
    let version: UInt32
    /// number of block locator hash entries
    let hashCount: VarInt
    /// block locator object; newest back to genesis block (dense to start, but then sparse)
    let blockLocatorHashes: Data
    /// hash of the last desired header; set to zero to get as many headers as possible (2000)
    let hashStop: Data

    func serialized() -> Data {
        var data = Data()
        data += version
        data += hashCount.serialized()
        data += blockLocatorHashes
        data += hashStop
        return data
    }
}
