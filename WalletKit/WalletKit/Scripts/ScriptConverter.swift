import Foundation

class ScriptConverter {

    func encode(script: Script) -> Data {
        var scriptData = Data()
        script.chunks.forEach { chunk in
            if let data = chunk.data {
                scriptData += OpCode.push(data)
            } else {
                scriptData += Data(bytes: [chunk.opCode])
            }
        }
        return scriptData
    }

    func decode(data: Data) throws -> Script {
        var chunks = [Chunk]()
        var it = 0
        while it < data.count {
            let opCode = data[it]
            switch opCode {
                case 0x01...0x4e:
                    let range = try getPushRange(data: data, it: it)
                    chunks.append(Chunk(scriptData: data, index: it, payloadRange: range))
                    it = range.upperBound
                default:
                    chunks.append(Chunk(scriptData: data, index: it, payloadRange: nil))
                    it += 1
            }
        }
        return Script(with: data, chunks: chunks)
    }

    private func getPushRange(data: Data, it: Int) throws -> Range<Int> {
        let opCode = data[it]

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
                    throw ScriptError.wrongScriptLength
                }
                bytesCount = Int(data[2]) << 8 + Int(data[1])
            case 0x4e:                              // The next four bytes contain the number of bytes to be pushed onto the stack in little endian order
                bytesOffset += 4
                guard data.count > 5 else {
                    throw ScriptError.wrongScriptLength
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
        guard let keyLength = bytesCount, data.count >= it + bytesOffset + keyLength else {
            throw ScriptError.wrongScriptLength
        }
        return Range(uncheckedBounds: (lower: it + bytesOffset, upper: it + bytesOffset + keyLength))
    }

}
