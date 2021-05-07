import PinKit

class BackupKeyService {
    let account: Account
    let words: [String]
    let salt: String
    private let pinKit: IPinKit

    init?(account: Account, pinKit: IPinKit) {
        guard case let .mnemonic(words, salt) = account.type else {
            return nil
        }

        self.account = account
        self.words = words
        self.salt = salt
        self.pinKit = pinKit
    }

}

extension BackupKeyService {

    var isPinSet: Bool {
        pinKit.isPinSet
    }

}
