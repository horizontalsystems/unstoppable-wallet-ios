import Foundation

class P2PKExtractor: ScriptExtractor {
    var type: ScriptType { return .p2pk }

    func extract(from script: Script, converter: ScriptConverter) throws -> Data {
        guard script.length >= type.keyLength else {
            throw ScriptError.wrongScriptLength
        }
        guard script.chunks.count == 2, script.chunks.last?.opCode == OpCode.checkSig, let result = script.chunks[0].data else {
            throw ScriptError.wrongSequence
        }
        return result
    }

}
