import Foundation
import HdWalletKit

class RestoreMnemonicService {
    private let wordsManager: IWordsManager

    private let wordList = Mnemonic.wordList(for: .english).map(String.init)

    init(wordsManager: IWordsManager) {
        self.wordsManager = wordsManager
    }

}

extension RestoreMnemonicService {

    func doesWordExist(word: String) -> Bool {
        wordList.contains(word)
    }

    func doesWordPartiallyExist(word: String) -> Bool {
        wordList.contains { $0.hasPrefix(word) }
    }

    func accountType(words: [String]) throws -> AccountType {
        guard words.count == 12 || words.count == 24 else {
            throw ValidationError.invalidWordsCount(count: words.count)
        }

        try Mnemonic.validate(words: words)

        return .mnemonic(words: words, salt: nil)
    }

}

extension RestoreMnemonicService {

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
