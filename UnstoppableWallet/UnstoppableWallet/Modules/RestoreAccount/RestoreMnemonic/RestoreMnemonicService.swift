import Foundation
import HdWalletKit
import RxSwift
import RxRelay

class RestoreMnemonicService {
    private let wordsManager: IWordsManager

    private let wordList = Mnemonic.wordList(for: .english).map(String.init)
    private let passphraseEnabledRelay = BehaviorRelay<Bool>(value: false)

    var passphrase: String = ""

    init(wordsManager: IWordsManager) {
        self.wordsManager = wordsManager
    }

}

extension RestoreMnemonicService {

    var passphraseEnabled: Bool {
        passphraseEnabledRelay.value
    }

    var passphraseEnabledObservable: Observable<Bool> {
        passphraseEnabledRelay.asObservable()
    }

    func set(passphraseEnabled: Bool) {
        passphraseEnabledRelay.accept(passphraseEnabled)
    }

    func doesWordExist(word: String) -> Bool {
        wordList.contains(word)
    }

    func doesWordPartiallyExist(word: String) -> Bool {
        wordList.contains { $0.hasPrefix(word) }
    }

    func accountType(words: [String]) throws -> AccountType {
        if passphraseEnabled, passphrase.isEmpty {
            throw RestoreError.emptyPassphrase
        }

        guard words.count == 12 || words.count == 24 else {
            throw ValidationError.invalidWordsCount(count: words.count)
        }

        try Mnemonic.validate(words: words)

        let salt = !passphrase.isEmpty ? passphrase : nil
        return .mnemonic(words: words, salt: salt)
    }

}

extension RestoreMnemonicService {

    enum RestoreError: Error {
        case emptyPassphrase
    }

    enum ValidationError: LocalizedError {
        case invalidWordsCount(count: Int)

        public var errorDescription: String? {
            switch self {
            case .invalidWordsCount(let count):
                return "restore_error.mnemonic_word_count".localized("\(count)")
            }
        }

    }

}
