import Foundation

class P2SHExtractor: ScriptExtractor {
    static let scriptLength = 23
    static let keyLength: UInt8 = 0x14

    let startSequence = Data(bytes: [OpCode.hash160, keyLength])
    let finishSequence = Data(bytes: [OpCode.equal])

    var type: ScriptType { return .p2sh }

    func extract(from data: Data) throws -> Data {
        guard data.count == P2SHExtractor.scriptLength else {
            throw ScriptExtractorError.wrongScriptLength
        }
        guard data.prefix(startSequence.count) == startSequence, data.suffix(from: data.count - finishSequence.count) == finishSequence else {
            throw ScriptExtractorError.wrongSequence
        }
        return data.subdata(in: Range(uncheckedBounds: (lower: startSequence.count, upper: data.count - finishSequence.count)))
    }

}
