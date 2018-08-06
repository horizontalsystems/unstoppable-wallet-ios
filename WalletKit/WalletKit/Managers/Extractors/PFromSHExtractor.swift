import Foundation

class PFromSHExtractor: ScriptExtractor {
    static let scriptLength = 25
    static let keyLength: UInt8 = 0x14

    let startSequence = Data(bytes: [OpCode.dup, OpCode.hash160, keyLength])
    let finishSequence = Data(bytes: [OpCode.equalVerify, OpCode.checkSig])

    var type: ScriptType { return .p2pkh }

    func extract(from data: Data) throws -> Data {
//        guard data.count == P2PKHExtractor.scriptLength else {
//            throw ScriptExtractorError.wrongScriptLength
//        }
//        guard data.prefix(startSequence.count) == startSequence, data.suffix(from: data.count - finishSequence.count) == finishSequence else {
//            throw ScriptExtractorError.wrongSequence
//        }
//        return data.subdata(in: Range(uncheckedBounds: (lower: startSequence.count, upper: data.count - finishSequence.count)))
        return Data()
    }

}
