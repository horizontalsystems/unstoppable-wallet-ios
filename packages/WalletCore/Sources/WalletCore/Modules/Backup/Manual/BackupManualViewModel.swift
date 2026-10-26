import Combine

class BackupManualViewModel: ObservableObject {
    let account: Account
    let words: [String]
    let passphrase: String?

    @Published private(set) var hidden = true

    init(account: Account) {
        self.account = account

        switch account.type {
        case let .mnemonic(words, salt, _):
            self.words = words
            passphrase = salt.isEmpty ? nil : salt
        case let .moneroMnemonic(words, passphrase):
            self.words = words
            self.passphrase = passphrase.isEmpty ? nil : passphrase
        default:
            words = []
            passphrase = nil
        }
    }

    var canVerify: Bool {
        !words.isEmpty
    }

    func toggleHidden() {
        hidden.toggle()
    }

    func copyPassphrase() {
        guard let passphrase else {
            return
        }

        CopyHelper.copyAndNotify(value: passphrase)
    }
}
