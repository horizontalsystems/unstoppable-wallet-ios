class BackupManualService {
    let account: Account
    let words: [String]
    let salt: String

    init?(account: Account) {
        switch account.type {
        case let .mnemonic(words, salt, _):
            self.words = words
            self.salt = salt
        case let .moneroMnemonic(words, passphrase):
            self.words = words
            salt = passphrase
        default:
            return nil
        }

        self.account = account
    }
}
