import Foundation

class PFromSHExtractor: ScriptExtractor {
    var type: ScriptType { return .p2sh }

    func extract(from script: Script) throws -> Data {
//        var it = 0
//        var lastData = Data()
//        while it < data.count {
//            let command = data[it]
//            switch command {
//                case 0x00, 0x4f, 0x51...0x60: it += 1
//                case 0x01...0x4b: break
//            }
//        }
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
