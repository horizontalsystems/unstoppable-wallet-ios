import Foundation
import HdWalletKit
import RxSwift
import RxRelay
import LanguageKit

class RestoreMnemonicNonStandardService {
    private let languageManager: LanguageManager
    private var wordList: [String] = Mnemonic.wordList(for: .english).map(String.init)
    private let passphraseEnabledRelay = BehaviorRelay<Bool>(value: false)

    private let regex = try! NSRegularExpression(pattern: "\\S+")
    private(set) var items: [WordItem] = []

    private let wordListLanguageRelay = PublishRelay<Mnemonic.Language>()
    private(set) var wordListLanguage: Mnemonic.Language = .english {
        didSet {
            wordListLanguageRelay.accept(wordListLanguage)
        }
    }

    var passphrase: String = ""

    init(languageManager: LanguageManager) {
        self.languageManager = languageManager
    }

    private func language(wordList: Mnemonic.Language) -> String {
        switch wordList {
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .spanish: return "es"
        case .simplifiedChinese: return "zh-Hans"
        case .traditionalChinese: return "zh-Hant"
        case .french: return "fr"
        case .italian: return "it"
        case .czech: return "cs"
        case .portuguese: return "pt"
        }
    }

}

extension RestoreMnemonicNonStandardService {

    var wordListLanguageObservable: Observable<Mnemonic.Language> {
        wordListLanguageRelay.asObservable()
    }

    var passphraseEnabled: Bool {
        passphraseEnabledRelay.value
    }

    var passphraseEnabledObservable: Observable<Bool> {
        passphraseEnabledRelay.asObservable()
    }

    func displayName(wordList: Mnemonic.Language) -> String {
        languageManager.displayName(language: language(wordList: wordList)) ?? "\(wordList)"
    }

    func set(wordListLanguage: Mnemonic.Language) {
        self.wordListLanguage = wordListLanguage
        wordList = Mnemonic.wordList(for: wordListLanguage).map(String.init)
    }

    func syncItems(text: String) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: (text as NSString).length))

        items = matches.compactMap { match in
            guard let range = Range(match.range, in: text) else {
                return nil
            }

            let word = String(text[range]).lowercased()

            let type: WordItemType

            if wordList.contains(word) {
                type = .correct
            } else if wordList.contains(where: { $0.hasPrefix(word) }) {
                type = .correctPrefix
            } else {
                type = .incorrect
            }

            return WordItem(word: word, range: match.range, type: type)
        }
    }

    func possibleWords(string: String) -> [String] {
        wordList.filter { $0.hasPrefix(string) }
    }

    func set(passphraseEnabled: Bool) {
        passphraseEnabledRelay.accept(passphraseEnabled)
    }

    func accountType(words: [String]) throws -> AccountType {
        var errors = [Error]()
        if passphraseEnabled, passphrase.isEmpty {
            errors.append(RestoreError.emptyPassphrase)
        }

        do {
            try Mnemonic.validate(words: words)
        } catch {
            errors.append(error)
        }

        guard errors.isEmpty else {
            throw ErrorList.errors(errors)
        }

        return .mnemonic(words: words, salt: passphrase, bip39Compliant: false)
    }

}

extension RestoreMnemonicNonStandardService {

    enum WordItemType {
        case correct
        case incorrect
        case correctPrefix
    }

    struct WordItem {
        let word: String
        let range: NSRange
        let type: WordItemType
    }

    enum RestoreError: Error {
        case emptyPassphrase
    }

    enum ErrorList: Error {
        case errors([Error])
    }

}
