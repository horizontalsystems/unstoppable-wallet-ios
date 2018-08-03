import Foundation

class P2PKExtractor: ScriptExtractor {
    static let minimalScriptLength = 3
    static let keyLength: UInt8 = 0x14

    let finishSequence = Data(bytes: [OpCode.checkSig])

    var type: ScriptType { return .p2pk }

    func extract(from data: Data) throws -> Data {
        guard data.count >= P2PKExtractor.minimalScriptLength else {
            throw ScriptExtractorError.wrongScriptLength
        }
        let opCode = data[0]
        var bytesCount: Int?
        var bytesOffset = 1
        switch opCode {
            case 0x01...0x4b: bytesCount = Int(opCode)
            case 0x4c:                              // The next byte contains the number of bytes to be pushed onto the stack
                bytesOffset += 1
                bytesCount = Int(data[1])
            case 0x4d:                              // The next two bytes contain the number of bytes to be pushed onto the stack in little endian order
                bytesOffset += 2
                guard data.count > 2 else {
                    throw ScriptExtractorError.wrongScriptLength
                }
                bytesCount = Int(data[2]) << 8 + Int(data[1])
            case 0x4e:                              // The next four bytes contain the number of bytes to be pushed onto the stack in little endian order
                bytesOffset += 4
                guard data.count > 5 else {
                    throw ScriptExtractorError.wrongScriptLength
                }
                var index = bytesOffset
                var count = 0
                while index >= 0 {
                    count += count << 8 + Int(data[1 + index])
                    index -= 1
                }
                bytesCount = count
            default: break
        }
        guard let keyLength = bytesCount else {
            throw ScriptExtractorError.wrongSequence
        }

        guard data.count == bytesOffset + keyLength + finishSequence.count else {
            throw ScriptExtractorError.wrongScriptLength
        }
        guard data.suffix(from: data.count - finishSequence.count) == finishSequence else {
            throw ScriptExtractorError.wrongSequence
        }
        return data.subdata(in: Range(uncheckedBounds: (lower: bytesOffset, upper: data.count - finishSequence.count)))
    }

}
