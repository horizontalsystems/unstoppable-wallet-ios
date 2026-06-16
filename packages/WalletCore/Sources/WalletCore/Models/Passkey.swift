import Foundation

// TODO: For AA + Tron GasFree we must provide seed, not mnemonic.
// Abstraction signers (EcdsaUserOpSigner, GasFreeTip712Signer) currently decode
// mnemonic→seed via Mnemonic.seed(...) themselves, leaking BIP39 into the AA layer.
public struct Passkey {
    public let credentialID: Data
    public let name: String
    public let mnemonic: [String]
}
