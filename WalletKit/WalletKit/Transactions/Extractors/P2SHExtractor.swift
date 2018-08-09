import Foundation

class P2SHExtractor: ScriptExtractor {
    static let scriptLength = 23

    var type: ScriptType { return .p2sh }

    func extract(from data: Data) throws -> Data {
        guard data.count == P2SHExtractor.scriptLength else {
            throw ScriptExtractorError.wrongScriptLength
        }
        let startWithPushByte = OpCode.p2shStart + ScriptType.p2sh.keyLength

        guard data.prefix(startWithPushByte.count) == startWithPushByte, data.suffix(from: data.count - OpCode.p2shFinish.count) == OpCode.p2shFinish else {
            throw ScriptExtractorError.wrongSequence
        }
        return data.subdata(in: Range(uncheckedBounds: (lower: startWithPushByte.count, upper: data.count - OpCode.p2shFinish.count)))
    }

}
