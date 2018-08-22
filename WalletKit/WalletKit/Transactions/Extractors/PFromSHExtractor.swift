import Foundation

class PFromSHExtractor: ScriptExtractor {
    var type: ScriptType { return .p2sh }

    func extract(from script: Script, converter: ScriptConverter) throws -> Data {
        guard let chunkData = script.chunks.last?.data else {
            throw ScriptError.wrongScriptLength
        }
        let redeemScript = try converter.decode(data: chunkData)
        var verifyChunkCode: UInt8 = 0
        guard let opCode = redeemScript.chunks.last?.opCode else {
            throw ScriptError.wrongSequence
        }
        verifyChunkCode = opCode
        if verifyChunkCode == OpCode.endIf { // check pre-last chunk
            if redeemScript.chunks.count > 1, let opCode = redeemScript.chunks.suffix(2).first?.opCode {
                verifyChunkCode = opCode
            } else {
                throw ScriptError.wrongSequence
            }
        }
        guard OpCode.pFromShCodes.contains(verifyChunkCode) else {
            throw ScriptError.wrongSequence
        }

        return chunkData
    }

}
