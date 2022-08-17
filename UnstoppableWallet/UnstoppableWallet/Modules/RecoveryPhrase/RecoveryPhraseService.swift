class RecoveryPhraseService {
    let words: [String]
    let salt: String

    init?(account: Account) {
        guard case let .mnemonic(words, salt) = account.type else {
            return nil
        }

        self.words = words
        self.salt = salt
    }

}
