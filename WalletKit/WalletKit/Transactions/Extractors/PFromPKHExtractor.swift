import Foundation

class PFromPKHExtractor: ScriptExtractor {
    var type: ScriptType { return .p2pkh }

    func extract(from script: Script, converter: ScriptConverter) throws -> Data {
        guard script.chunks.count == 2, let sigData = script.chunks[0].data, let keyData = script.chunks[1].data else {
            throw ScriptError.wrongSequence
        }
        guard abs(sigData.count - 73) < 3, keyData.count == 65 else {
            throw ScriptError.wrongSequence
        }
        return keyData
    }

}
