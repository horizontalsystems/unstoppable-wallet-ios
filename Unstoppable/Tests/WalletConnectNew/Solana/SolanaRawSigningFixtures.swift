import Foundation

// Independent vector generated with python `cryptography` (Ed25519) + SLIP-0010 m/44'/501'/0'/0':
// legacy transaction with two required signers — fee payer `other` (already signed) and `ours`.
enum SolanaRawSigningFixtures {
    static let seed = data(hex: "c914accd10a4a2d9e9103d5f94e903aec5b22f147e7ecc16ef94386e77f9247853dafa966376723826d38c2c082793b84f2462cefb2d2e8a6cbedf0a0718bf6a")
    static let foreignSeed = data(hex: "656771905e1ef731f65cd0a0d9fb061238380a1a012e6abdf846ecc7d2ea36fd656771905e1ef731f65cd0a0d9fb061238380a1a012e6abdf846ecc7d2ea36fd")
    static let ours = "C3sMV8TJunZCdA8QTPpqjgtmm3iKYAWsARjLwqXsDxoB"
    static let other = "meHJjLUcsxmQm2hUyPdVYyq68q7wqK24vGLSdum2yMC"
    static let oursPublicKey = data(hex: "a42ca6ffcacc25bb7bdab66cc7723f5ae9db42dffe0ab841e66a642f7d8b8ef2")
    static let partiallySigned = data(hex: "02215bed2cd324b24c545540803c2d1b349642c6afa90fd28510c60b7b11443f693f8e57e08be7b0f93c3153655677e380436a9ea41c5f9376846eaa7a505f0f0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020001030b6fb5a277227cab7be734d1807a69c37eb93c0f44660b927d14ca6955755e5ba42ca6ffcacc25bb7bdab66cc7723f5ae9db42dffe0ab841e66a642f7d8b8ef20000000000000000000000000000000000000000000000000000000000000000395bf727f9aac5e80911591073fcf9c826f428804131ca089beba3869421749a01020200010c02000000e803000000000000")
    static let fullySigned = data(hex: "02215bed2cd324b24c545540803c2d1b349642c6afa90fd28510c60b7b11443f693f8e57e08be7b0f93c3153655677e380436a9ea41c5f9376846eaa7a505f0f0338a6f926e3d0aee76f6abe28418aaf50530a52ea74168e851a7d774d46480af69cd4ed5163b408779f574e9447432ce929e3325e3604c8c474e33513b4d89304020001030b6fb5a277227cab7be734d1807a69c37eb93c0f44660b927d14ca6955755e5ba42ca6ffcacc25bb7bdab66cc7723f5ae9db42dffe0ab841e66a642f7d8b8ef20000000000000000000000000000000000000000000000000000000000000000395bf727f9aac5e80911591073fcf9c826f428804131ca089beba3869421749a01020200010c02000000e803000000000000")

    private static func data(hex: String) -> Data {
        var bytes = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            bytes.append(UInt8(hex[index ..< next], radix: 16) ?? 0)
            index = next
        }
        return Data(bytes)
    }
}
