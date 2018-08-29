import Foundation

struct FilterAddMessage {
    let elementBytes: VarInt
    let element: Data

    func serialized() -> Data {
        var data = Data()
        data += elementBytes.serialized()
        data += element
        return data
    }
}
