import Foundation

enum ScriptExtractorError: Error { case wrongScriptLength, wrongSequence }

protocol ScriptExtractor {
    var type: ScriptType { get }
    func extract(from data: Data) throws -> Data
}

class TransactionExtractor {
    static let defaultExtractors: [ScriptExtractor] = [P2PKHExtractor(), P2PKExtractor(), P2SHExtractor()]
    static let shared = TransactionExtractor()

    enum ExtractionError: Error {
        case invalid
    }

    let scriptExtractors: [ScriptExtractor]

    init(scriptExtractors: [ScriptExtractor] = TransactionExtractor.defaultExtractors) {
        self.scriptExtractors = scriptExtractors
    }

    func extract(message: Transaction) throws {
        var valid: Bool = false
        message.outputs.forEach { output in
            var payload: Data?
            for extractor in scriptExtractors {
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
        if !valid {
            throw ExtractionError.invalid
        }
//        try message.inputs.forEach { input in
//            do {
//                let payload = try transactionEncoder.extractPayloads(from: input.signatureScript)
//                data.append(contentsOf: payload)
//            } catch {
//                throw error
//            }
//        }
    }

}
