import Foundation

enum ScriptError: Error { case wrongScriptLength, wrongSequence }

protocol ScriptExtractor: class {
    var type: ScriptType { get }
    func extract(from script: Script, converter: ScriptConverter) throws -> Data
}

class TransactionExtractor {
    static let defaultInputExtractors: [ScriptExtractor] = [PFromSHExtractor()]
    static let defaultOutputExtractors: [ScriptExtractor] = [P2PKHExtractor(), P2PKExtractor(), P2SHExtractor()]

    enum ExtractionError: Error {
        case invalid
    }

    let scriptInputExtractors: [ScriptExtractor]
    let scriptOutputExtractors: [ScriptExtractor]
    let scriptConverter: ScriptConverter
    let addressConverter: AddressConverter

    init(scriptInputExtractors: [ScriptExtractor] = TransactionExtractor.defaultInputExtractors, scriptOutputExtractors: [ScriptExtractor] = TransactionExtractor.defaultOutputExtractors,
         scriptConverter: ScriptConverter, addressConverter: AddressConverter) {
        self.scriptInputExtractors = scriptInputExtractors
        self.scriptOutputExtractors = scriptOutputExtractors
        self.scriptConverter = scriptConverter
        self.addressConverter = addressConverter
    }

    func extract(transaction: Transaction) throws {
        var valid: Bool = false
        transaction.outputs.forEach { output in
            var payload: Data?
            for extractor in scriptOutputExtractors {
                do {
                    let script = try scriptConverter.decode(data: output.lockingScript)
                    payload = try extractor.extract(from: script, converter: scriptConverter)
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

            if let keyHash = output.keyHash, let address = try? addressConverter.convert(keyHash: keyHash, type: output.scriptType) {
                output.address = address
            }
        }

        transaction.inputs.forEach { input in
            var payload: Data?
            for extractor in scriptInputExtractors {
                do {
                    let script = try scriptConverter.decode(data: input.signatureScript)
                    payload = try extractor.extract(from: script, converter: scriptConverter)
                } catch {
//                    print("\(error)")
                }
                if let payload = payload {
                    valid = true
                    switch extractor.type {
                        case .p2sh: input.publicKey = Crypto.sha256ripemd160(payload)
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
