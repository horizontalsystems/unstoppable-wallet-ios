import Combine
import Foundation
import HdWalletKit
import MoneroKit

class RestoreMnemonicViewModel: ObservableObject {
    private let accountFactory = Core.shared.accountFactory

    // MARK: - Mnemonic state

    private var wordList: [String] = Mnemonic.wordList(for: .english).map(String.init)
    private let regex = try! NSRegularExpression(pattern: "\\S+")
    private var mnemonicItems: [WordItem] = []
    private var selectedLanguage: Mnemonic.Language = .english
    private var wordListKind: WordListKind?
    private var passphrase: String = ""
    private var cursorOffset = 0

    // MARK: - Published

    @Published var name: String {
        didSet {
            buttonEnabled = !resolvedName.isEmpty
        }
    }

    @Published var possibleWords: [String] = []
    @Published var invalidRanges: [NSRange] = []
    @Published var mnemonicCaution: CautionState = .none
    @Published var wordListLanguage: String = ""

    @Published var advanced = false
    @Published var buttonEnabled = true

    private let proceedSubject = PassthroughSubject<(String, AccountType), Never>()
    private let replaceWordSubject = PassthroughSubject<(NSRange, String), Never>()

    init() {
        name = accountFactory.generatedAccountName
        wordListLanguage = displayName(language: selectedLanguage)
    }

    // MARK: - Private helpers

    private func languageCode(for language: Mnemonic.Language) -> String {
        switch language {
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

    private func displayName(language: Mnemonic.Language) -> String {
        LanguageManager.shared.displayName(language: languageCode(for: language)) ?? "\(language)"
    }

    private func syncMnemonicItems(text: String) {
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: (text as NSString).length))

        let words: [(word: String, range: NSRange)] = matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return (String(text[range]).lowercased(), match.range)
        }

        // The BIP39 and Monero wordlists overlap; the first finished word that belongs to
        // exactly one of them fixes the wordlist. The word under the cursor is still being typed.
        wordListKind = words
            .filter { !hasCursor(range: $0.range) }
            .compactMap { Self.exclusiveWordListKind(word: $0.word, bip39WordList: wordList) }
            .first

        mnemonicItems = words.map { word, range in
            let type: WordItemType

            if isValidWord(word, partial: false) {
                type = .correct
            } else if isValidWord(word, partial: true) {
                type = .correctPrefix
            } else {
                type = .incorrect
            }

            return WordItem(word: word, range: range, type: type)
        }
    }

    private static func isBip39Word(_ word: String, wordList: [String], partial: Bool) -> Bool {
        partial ? wordList.contains { $0.hasPrefix(word) } : wordList.contains(word)
    }

    private static func exclusiveWordListKind(word: String, bip39WordList: [String]) -> WordListKind? {
        switch (isBip39Word(word, wordList: bip39WordList, partial: false), MoneroMnemonic.isValid(word: word)) {
        case (true, false): return .bip39
        case (false, true): return .monero
        default: return nil
        }
    }

    private func isValidWord(_ word: String, partial: Bool) -> Bool {
        switch wordListKind {
        case .bip39: return Self.isBip39Word(word, wordList: wordList, partial: partial)
        case .monero: return MoneroMnemonic.isValid(word: word, partial: partial)
        case nil: return Self.isBip39Word(word, wordList: wordList, partial: partial) || MoneroMnemonic.isValid(word: word, partial: partial)
        }
    }

    private func possibleMnemonicWords(string: String) -> [String] {
        let bip39Words = wordList.filter { $0.hasPrefix(string) }
        let moneroWords = MoneroMnemonic.suggestions(prefix: string)

        switch wordListKind {
        case .bip39: return bip39Words
        case .monero: return moneroWords
        case nil: return bip39Words + moneroWords.filter { !bip39Words.contains($0) }
        }
    }

    private func hasCursor(range: NSRange) -> Bool {
        cursorOffset >= range.lowerBound && cursorOffset <= range.upperBound
    }

    private var cursorItem: WordItem? {
        mnemonicItems.first { hasCursor(range: $0.range) }
    }

    private var resolvedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resolveAccountType(words: [String]) throws -> AccountType {
        let passphrase = advanced ? passphrase : ""

        try Mnemonic.validate(words: words)

        return .mnemonic(
            words: words.map(\.decomposedStringWithCompatibilityMapping),
            salt: passphrase.decomposedStringWithCompatibilityMapping,
            bip39Compliant: true
        )
    }

    private func resolveMoneroAccountType(words: [String]) throws -> AccountType {
        let invalidItems = mnemonicItems.filter { !MoneroMnemonic.isValid(word: $0.word) }
        guard invalidItems.isEmpty else {
            invalidRanges = invalidItems.map(\.range)
            throw MoneroRestoreError.invalidChecksum
        }

        do {
            try MoneroMnemonic.validateChecksum(words: words)
        } catch {
            throw MoneroRestoreError.invalidChecksum
        }

        let rawPassphrase = advanced ? passphrase : ""
        // A whitespace-only passphrase collapses to empty: backup serialization drops blank
        // passphrases, so a whitespace-only seed offset would silently restore a different
        // wallet after a backup round-trip. Matches the Android implementation.
        let resolvedPassphrase = rawPassphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : rawPassphrase

        return .moneroMnemonic(
            words: words.map(\.decomposedStringWithCompatibilityMapping),
            passphrase: resolvedPassphrase
        )
    }
}

// MARK: - Public interface

extension RestoreMnemonicViewModel {
    var proceedPublisher: AnyPublisher<(String, AccountType), Never> { proceedSubject.eraseToAnyPublisher() }
    var replaceWordPublisher: AnyPublisher<(NSRange, String), Never> { replaceWordSubject.eraseToAnyPublisher() }

    var wordListViewItems: [AlertViewItem] {
        Mnemonic.Language.allCases.map { language in
            AlertViewItem(text: displayName(language: language), selected: language == selectedLanguage)
        }
    }

    func refreshName() {
        name = accountFactory.generatedAccountName
    }

    func onSelectWordList(index: Int) {
        let language = Mnemonic.Language.allCases[index]
        selectedLanguage = language
        wordList = Mnemonic.wordList(for: language).map(String.init)
        wordListLanguage = displayName(language: language)
    }

    func onChange(text: String, cursorOffset: Int) {
        self.cursorOffset = cursorOffset
        syncMnemonicItems(text: text)

        mnemonicCaution = .none

        let nonCursorInvalidItems = mnemonicItems.filter { item in
            switch item.type {
            case .correct: return false
            case .incorrect: return true
            case .correctPrefix: return !hasCursor(range: item.range)
            }
        }

        invalidRanges = nonCursorInvalidItems.map(\.range)

        if let cursorItem {
            possibleWords = possibleMnemonicWords(string: cursorItem.word)
        } else {
            possibleWords = []
        }
    }

    func onSelect(word: String) {
        guard let cursorItem else { return }
        replaceWordSubject.send((cursorItem.range, word))
    }

    func onChange(passphrase: String) {
        self.passphrase = passphrase
    }

    func onTapProceed() {
        mnemonicCaution = .none

        guard mnemonicItems.allSatisfy({ $0.type == .correct }) else {
            invalidRanges = mnemonicItems.filter { $0.type != .correct }.map(\.range)
            return
        }

        do {
            let words = mnemonicItems.map(\.word)

            let accountType: AccountType
            switch wordListKind {
            case .monero:
                accountType = try resolveMoneroAccountType(words: words)
            case .bip39:
                accountType = try resolveAccountType(words: words)
            case nil:
                // Every word is in both wordlists, so only the count tells: BIP39 tops out at 24
                if words.count == MoneroMnemonic.wordCount {
                    accountType = try resolveMoneroAccountType(words: words)
                } else {
                    accountType = try resolveAccountType(words: words)
                }
            }

            proceedSubject.send((resolvedName, accountType))
        } catch MoneroRestoreError.invalidChecksum {
            mnemonicCaution = .caution(Caution(text: "restore.checksum_error".localized, type: .error))
        } catch {
            mnemonicCaution = .caution(Caution(text: error.convertedError.smartDescription, type: .error))
        }
    }
}

// MARK: - Types

extension RestoreMnemonicViewModel {
    enum WordListKind {
        case bip39
        case monero
    }

    enum MoneroRestoreError: Error {
        case invalidChecksum
    }

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
}
