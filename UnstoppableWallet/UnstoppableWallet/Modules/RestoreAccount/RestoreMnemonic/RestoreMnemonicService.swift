import Foundation
import HdWalletKit
import RxSwift
import RxRelay

class RestoreMnemonicService {
    private var wordList: [String] = Mnemonic.wordList(for: .english).map(String.init)
    private let passphraseEnabledRelay = BehaviorRelay<Bool>(value: false)

    private let regex = try! NSRegularExpression(pattern: "\\S+")
    private(set) var items: [WordItem] = []

    var passphrase: String = ""
}

extension RestoreMnemonicService {

    var passphraseEnabled: Bool {
        passphraseEnabledRelay.value
    }

    var passphraseEnabledObservable: Observable<Bool> {
        passphraseEnabledRelay.asObservable()
    }

    func set(language: String?) {
        var mnemonicLanguage: Mnemonic.Language = .english

        if let language = language {
            if language.hasPrefix("ja-") { mnemonicLanguage = .japanese }
            else if language.hasPrefix("ko-") { mnemonicLanguage = .korean }
            else if language.hasPrefix("es-") { mnemonicLanguage = .spanish }
            else if language == "zh-Hans" { mnemonicLanguage = .simplifiedChinese }
            else if language == "zh-Hant" { mnemonicLanguage = .traditionalChinese }
            else if language.hasPrefix("fr-") { mnemonicLanguage = .french }
            else if language.hasPrefix("it-") { mnemonicLanguage = .italian }
            else if language.hasPrefix("cs-") { mnemonicLanguage = .czech }
            else if language.hasPrefix("pt-") { mnemonicLanguage = .portuguese }
        }

        wordList = Mnemonic.wordList(for: mnemonicLanguage).map(String.init)
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

        return .mnemonic(words: words, salt: passphrase)
    }

}

extension RestoreMnemonicService {

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
