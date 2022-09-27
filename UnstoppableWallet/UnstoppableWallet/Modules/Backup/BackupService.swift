class BackupService {
    let account: Account
    let words: [String]
    let salt: String

    init?(account: Account) {
        guard case let .mnemonic(words, salt) = account.type else {
            return nil
        }

        self.account = account
        self.words = words
        self.salt = salt
    }

}
