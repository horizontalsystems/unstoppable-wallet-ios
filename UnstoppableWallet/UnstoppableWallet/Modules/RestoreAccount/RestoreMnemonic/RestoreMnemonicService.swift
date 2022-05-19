import Foundation
import HdWalletKit
import RxSwift
import RxRelay

class RestoreMnemonicService {
    private let wordsManager: WordsManager

    private let wordList = Mnemonic.wordList(for: .english).map(String.init)
    private let passphraseEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let passphraseValidator: PassphraseValidator

    var passphrase: String = ""
    let defaultName: String
    private var name: String = ""

    init(accountFactory: AccountFactory, wordsManager: WordsManager, passphraseValidator: PassphraseValidator) {
        self.wordsManager = wordsManager
        self.passphraseValidator = passphraseValidator

        defaultName = accountFactory.nextAccountName
    }

}

extension RestoreMnemonicService {

    var passphraseEnabled: Bool {
        passphraseEnabledRelay.value
    }

    var passphraseEnabledObservable: Observable<Bool> {
        passphraseEnabledRelay.asObservable()
    }

    var resolvedName: String {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? defaultName : name
    }

    func set(name: String) {
        self.name = name
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

    func validate(text: String?) -> Bool {
        passphraseValidator.validate(text: text)
    }

    func accountType(words: [String]) throws -> AccountType {
        if passphraseEnabled, passphrase.isEmpty {
            throw RestoreError.emptyPassphrase
        }

        guard words.count == 12 || words.count == 24 else {
            throw ValidationError.invalidWordsCount(count: words.count)
        }

        try Mnemonic.validate(words: words)

        return .mnemonic(words: words, salt: passphrase)
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
