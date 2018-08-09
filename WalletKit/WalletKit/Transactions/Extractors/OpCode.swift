import Foundation

class OpCode {
    static let p2pkhStart = Data(bytes: [OpCode.dup, OpCode.hash160])
    static let p2pkhFinish = Data(bytes: [OpCode.equalVerify, OpCode.checkSig])

    static let p2pkFinish = Data(bytes: [OpCode.checkSig])

    static let p2shStart = Data(bytes: [OpCode.hash160])
    static let p2shFinish = Data(bytes: [OpCode.equal])

    static let pushData1: UInt8 = 0x4c
    static let pushData2: UInt8 = 0x4d
    static let pushData4: UInt8 = 0x4e
    static let dup: UInt8 = 0x76
    static let hash160: UInt8 = 0xA9
    static let equal: UInt8 = 0x87
    static let equalVerify: UInt8 = 0x88
    static let checkSig: UInt8 = 0xAC

    static func push(_ data: Data) -> Data {
        let length = data.count
        var bytes = Data()

        switch length {
        case 0x00...0x4b: bytes = Data(bytes: [UInt8(length)])
        case 0x4c...0xff: bytes = Data(bytes: [OpCode.pushData1]) + UInt8(length).littleEndian
        case 0x0100...0xffff: bytes = Data(bytes: [OpCode.pushData2]) + UInt16(length).littleEndian
        case 0x10000...0xffffffff: bytes = Data(bytes: [OpCode.pushData4]) + UInt32(length).littleEndian
        default: return data
        }

        return bytes + data
    }

}
