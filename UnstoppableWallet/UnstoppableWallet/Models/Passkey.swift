import Foundation

// TODO: For AA + Tron GasFree we must provide seed, not mnemonic.
// Abstraction signers (EcdsaUserOpSigner, GasFreeTip712Signer) currently decode
// mnemonic→seed via Mnemonic.seed(...) themselves, leaking BIP39 into the AA layer.
struct Passkey {
    let credentialID: Data
    let name: String
    let mnemonic: [String]
}
