import Foundation

class P2PKHExtractor: ScriptExtractor {
    static let scriptLength = 25
    var type: ScriptType { return .p2pkh }

    func extract(from script: Script) throws -> Data {
        guard script.length == P2PKHExtractor.scriptLength else {
            throw ScriptError.wrongScriptLength
        }
        guard script.chunks.count == 5 else {
            throw ScriptError.wrongSequence
        }
        let validCodes = OpCode.p2pkhStart + Data(bytes: [0x14]) + OpCode.p2pkhFinish
        try script.validate(opCodes: validCodes)

        guard let pushData = script.chunks[2].data else {
            throw ScriptError.wrongSequence
        }
        return pushData
    }

}
