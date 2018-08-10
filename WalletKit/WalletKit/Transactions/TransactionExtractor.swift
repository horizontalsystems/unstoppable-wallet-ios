import Foundation

enum ScriptExtractorError: Error { case wrongScriptLength, wrongSequence }

protocol ScriptExtractor: class {
    var type: ScriptType { get }
    func extract(from data: Data) throws -> Data
}

class TransactionExtractor {
    static let defaultInputExtractors: [ScriptExtractor] = [PFromSHExtractor()]
    static let defaultOutputExtractors: [ScriptExtractor] = [P2PKHExtractor(), P2PKExtractor(), P2SHExtractor()]

    enum ExtractionError: Error {
        case invalid
    }

    let scriptInputExtractors: [ScriptExtractor]
    let scriptOutputExtractors: [ScriptExtractor]

    init(scriptInputExtractors: [ScriptExtractor] = TransactionExtractor.defaultInputExtractors, scriptOutputExtractors: [ScriptExtractor] = TransactionExtractor.defaultOutputExtractors) {
        self.scriptInputExtractors = scriptInputExtractors
        self.scriptOutputExtractors = scriptOutputExtractors
    }

    func extract(message: Transaction) throws {
        var valid: Bool = false
        message.outputs.forEach { output in
            var payload: Data?
            for extractor in scriptOutputExtractors {
                do {
                    payload = try extractor.extract(from: output.lockingScript)
                } catch {
//                    print("\(error)")
                }
                if let payload = payload {
                    valid = true
                    output.scriptType = extractor.type
                    switch extractor.type {
                        case .p2pkh: output.keyHash = payload
                        case .p2pk: output.keyHash = Crypto.sha256ripemd160(payload)
                        case .p2sh: output.keyHash = payload
                        default: break
                    }
                    break
                }
            }
        }

        message.inputs.forEach { input in
            var payload: Data?
            for extractor in scriptInputExtractors {
                do {
                    payload = try extractor.extract(from: input.signatureScript)
                } catch {
//                    print("\(error)")
                }
                if let payload = payload {
                    valid = true
                    switch extractor.type {
                        case .p2sh: input.publicKey = payload
                        default: break
                    }
                    break
                }
            }
        }

        if !valid {
            throw ExtractionError.invalid
        }
    }

}
