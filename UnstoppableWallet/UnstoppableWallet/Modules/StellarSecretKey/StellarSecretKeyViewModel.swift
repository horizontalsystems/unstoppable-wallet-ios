import stellarsdk

class StellarSecretKeyViewModel {
    let secretKey: String

    init?(accountType: AccountType) {
        switch accountType {
        case let .mnemonic(words, salt, _):
            do {
                let keyPair = try WalletUtils.createKeyPair(mnemonic: words.joined(separator: " "), passphrase: salt, index: 0)

                if let secretKey = keyPair.secretSeed {
                    self.secretKey = secretKey
                } else {
                    return nil
                }
            } catch {
                return nil
            }
        case let .stellarSecretKey(secretSeed):
            secretKey = secretSeed
        default: return nil
        }
    }
}
