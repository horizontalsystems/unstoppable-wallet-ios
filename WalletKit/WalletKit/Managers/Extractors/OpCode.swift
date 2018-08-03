import Foundation

class OpCode {
    static let dup: UInt8 = 0x76
    static let hash160: UInt8 = 0xA9
    static let equal: UInt8 = 0x87
    static let equalVerify: UInt8 = 0x88
    static let checkSig: UInt8 = 0xAC
}
