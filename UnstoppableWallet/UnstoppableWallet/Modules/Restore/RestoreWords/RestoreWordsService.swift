import Foundation
import RxSwift
import RxRelay
import HdWalletKit

class RestoreWordsService {
    private let restoreAccountType: RestoreWordsModule.RestoreAccountType
    private let wordsManager: IWordsManager

    private let wordList = Mnemonic.wordList(for: .english).map(String.init)

    init(restoreAccountType: RestoreWordsModule.RestoreAccountType, wordsManager: IWordsManager) {
        self.restoreAccountType = restoreAccountType
        self.wordsManager = wordsManager
    }
}

extension RestoreWordsService {

    var wordCount: Int {
        switch restoreAccountType {
        case .mnemonic(let wordsCount):
            return wordsCount
        case .zcash:
            return 24
        }
    }

    var birthdayHeightEnabled: Bool {
        switch restoreAccountType {
        case .mnemonic: return false
        case .zcash: return true
        }
    }

    var accountTitle: String {
        switch restoreAccountType {
        case .mnemonic(let wordsCount): return wordsCount == 24 ? PredefinedAccountType.binance.title : PredefinedAccountType.standard.title
        case .zcash: return PredefinedAccountType.zcash.title
        }
    }

    func isWordExists(word: String) -> Bool {
        wordList.contains(word)
    }

    func isWordPartiallyExists(word: String) -> Bool {
        wordList.contains { $0.hasPrefix(word) }
    }

    func accountType(words: [String], birthdayHeight: Int?) throws -> AccountType {
        guard words.count == wordCount else {
            throw ValidationError.invalidWordsCount(count: words.count, requiredCount: wordCount)
        }

        try Mnemonic.validate(words: words)

        switch restoreAccountType {
        case .mnemonic:
            return .mnemonic(words: words, salt: nil)
        case .zcash:
            return .zcash(words: words, birthdayHeight: birthdayHeight)
        }
    }

}

extension RestoreWordsService {

    enum ValidationError: LocalizedError {
        case invalidWord(word: String)
        case invalidWordsCount(count: Int, requiredCount: Int)

        public var errorDescription: String? {
            switch self {
            case .invalidWord(let word):
                return "invalid word: \(word)"
            case .invalidWordsCount(let count, let requiredCount):
                return "restore_error.words_count".localized("\(requiredCount)", "\(count)")
            }
        }

    }

}
