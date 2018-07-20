import Foundation

struct HeadersMessage {
    let count: VarInt
    let blockHeaders: [BlockHeaderItem]

//    public func serialized() -> Data {
//        var data = Data()
//        data += count.serialized()
//        data += blockHeaders.flatMap { $0.serialized() }
//        return data
//    }

    static func deserialize(_ data: Data) -> HeadersMessage {
        let byteStream = ByteStream(data)
        let count = byteStream.read(VarInt.self)

        var headers = [BlockHeaderItem]()
        for _ in 0..<Int(count.underlyingValue) {
            headers.append(BlockHeaderItem.deserialize(byteStream: byteStream))
            _ = byteStream.read(Data.self, count: 1)
        }

        return HeadersMessage(count: count, blockHeaders: headers)
    }
}
