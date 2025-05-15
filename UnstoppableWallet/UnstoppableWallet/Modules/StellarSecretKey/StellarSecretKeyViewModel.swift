import stellarsdk

class StellarSecretKeyViewModel {
    let secretKey: String

    init?(accountType: AccountType) {
        switch accountType {
        case let .mnemonic(words, salt, _):
            do {
                let keyPair = try WalletUtils.createKeyPair(mnemonic: words.joined(separator: " "), passphrase: salt, index: 0)
                secretKey = keyPair.secretSeed
            } catch {
                return nil
            }
        case let .stellarSecretKey(secretSeed):
            secretKey = secretSeed
        default: return nil
        }
    }
}
