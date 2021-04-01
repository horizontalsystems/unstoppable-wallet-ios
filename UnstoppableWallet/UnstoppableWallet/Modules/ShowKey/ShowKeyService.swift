import PinKit

class ShowKeyService {
    let words: [String]
    let salt: String?
    private let pinKit: IPinKit

    init?(account: Account, pinKit: IPinKit) {
        guard case let .mnemonic(words, salt) = account.type else {
            return nil
        }

        self.words = words
        self.salt = salt
        self.pinKit = pinKit
    }

}

extension ShowKeyService {

    var isPinSet: Bool {
        pinKit.isPinSet
    }

}
