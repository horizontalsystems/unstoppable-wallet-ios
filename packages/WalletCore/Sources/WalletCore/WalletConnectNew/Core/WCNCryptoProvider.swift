import CryptoSwift
import Foundation
import HsCryptoKit
import ReownWalletKit

struct WCNCryptoProvider: CryptoProvider {
    func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        let signature = Data(signature.r + signature.s + [signature.v])
        var publicKey = HsCryptoKit.Crypto.ellipticPublicKey(signature: signature, of: keccak256(message), compressed: false)
        publicKey?.remove(at: 0)
        return publicKey ?? Data()
    }

    func keccak256(_ data: Data) -> Data {
        Data(SHA3(variant: .keccak256).calculate(for: [UInt8](data)))
    }
}
