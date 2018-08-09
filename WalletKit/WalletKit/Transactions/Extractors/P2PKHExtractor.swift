import Foundation

class P2PKHExtractor: ScriptExtractor {
    static let scriptLength = 25
    var type: ScriptType { return .p2pkh }

    func extract(from data: Data) throws -> Data {
        guard data.count == P2PKHExtractor.scriptLength else {
            throw ScriptExtractorError.wrongScriptLength
        }
        let startWithPushByte = OpCode.p2pkhStart + ScriptType.p2pkh.keyLength
        guard data.prefix(startWithPushByte.count) == startWithPushByte, data.suffix(from: data.count - OpCode.p2pkhFinish.count) == OpCode.p2pkhFinish else {
            throw ScriptExtractorError.wrongSequence
        }
        return data.subdata(in: Range(uncheckedBounds: (lower: startWithPushByte.count, upper: data.count - OpCode.p2pkhFinish.count)))
    }

}
