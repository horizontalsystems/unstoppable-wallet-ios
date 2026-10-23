import Combine

class RecoveryPhraseViewModel: ObservableObject {
    let words: [String]
    let passphrase: String?

    @Published private(set) var hidden = true

    init(account: Account) {
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

    func toggleHidden() {
        hidden.toggle()
        stat(page: .recoveryPhrase, event: .toggleHidden)
    }

    func copy() {
        Coordinator.shared.presentCopyConfirmation(value: words.joined(separator: " ")) {
            stat(page: .recoveryPhrase, event: .copy(entity: .recoveryPhrase))
        }
    }

    func copyPassphrase() {
        guard let passphrase else {
            return
        }

        CopyHelper.copyAndNotify(value: passphrase)
        stat(page: .recoveryPhrase, event: .copy(entity: .passphrase))
    }
}
