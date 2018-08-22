import Foundation

class Script {
    let scriptData: Data
    private (set) var chunks: [Chunk]

    var length: Int { return scriptData.count }

    func validate(opCodes: Data) throws {
        guard opCodes.count == chunks.count else {
            throw ScriptError.wrongScriptLength
        }
        try chunks.enumerated().forEach { (index, chunk) in
            if chunk.opCode != opCodes[index] {
                throw ScriptError.wrongSequence
            }
        }
    }

    init(with data: Data, chunks: [Chunk]) {
        self.scriptData = data
        self.chunks = chunks
    }

}
