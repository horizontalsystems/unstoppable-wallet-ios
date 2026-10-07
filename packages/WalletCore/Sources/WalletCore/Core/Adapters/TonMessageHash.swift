import Foundation
import TonSwift

enum TonMessageHash {
    enum Error: Swift.Error {
        case notExternalIn
        case encodingFailed
    }

    // TEP-467 normalized hash of a signed external-in message boc (base64): 64-char lowercase hex, no 0x.
    // The message is re-serialized with src = addr_none, import_fee = 0, init = nothing and the body always
    // stored as a reference, so the result depends only on the destination and the body cell.
    static func normalized(boc: String) throws -> String {
        let cell = try TonSwift.Cell.fromBase64(src: boc)
        let message: Message = try cell.beginParse().loadType()

        guard case let .externalInInfo(info) = message.info else {
            throw Error.notExternalIn
        }

        guard let importFee = Coins(rawValue: 0) else {
            throw Error.encodingFailed
        }

        let builder = Builder()
        try builder.store(bit: true) // ext_in_msg_info$10
        try builder.store(bit: false)
        try builder.store(bit: false) // src = addr_none$00
        try builder.store(bit: false)
        try builder.store(info.dest) // dest:MsgAddressInt (addr_std$10 anycast:0 wc hash)
        try builder.store(importFee) // import_fee = 0
        try builder.store(bit: false) // init = nothing
        try builder.store(bit: true) // body as reference
        try builder.store(ref: message.body)

        return try builder.endCell().hash().hexString()
    }
}
