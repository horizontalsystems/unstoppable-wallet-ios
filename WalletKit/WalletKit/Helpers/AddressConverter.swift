import Foundation

class AddressConverter {
    let network: NetworkProtocol

    init(network: NetworkProtocol) {
        self.network = network
    }

    func convert(publicKeyHash: Data, type: ScriptType) throws -> String {
        let version: UInt8
        switch type {
            case .p2pkh, .p2pk: version = network.pubKeyHash
            case .p2sh: version = network.scriptHash
            default: throw ConversionError.unknownAddressType
        }
        var withVersion = (Data([version])) + publicKeyHash
        let doubleSHA256 = Crypto.sha256sha256(withVersion)
        let checksum = doubleSHA256.prefix(4)
        withVersion += checksum
        return Base58.encode(withVersion)
    }

    func convert(address: String) throws -> Data {
        guard address.count >= 34 && address.count <= 55 else {
            throw ConversionError.invalidAddressLength
        }
        let hex = Base58.decode(address)
        let givenChecksum = hex.suffix(4)
        let doubleSHA256 = Crypto.sha256sha256(hex.prefix(hex.count - 4))
        let actualChecksum = doubleSHA256.prefix(4)
        guard givenChecksum == actualChecksum else {
            throw ConversionError.invalidChecksum
        }
        return hex[1..<hex.count - 4]
    }
}

enum ConversionError: Error {
    case invalidChecksum
    case invalidAddressLength
    case unknownAddressType
}
