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

        mnemonicItems = matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            let word = String(text[range]).lowercased()
            let type: WordItemType

            // Monero legacy words are accepted alongside the BIP39 list; the two wordlists
            // are fully disjoint, so a finished phrase is unambiguous.
            if wordList.contains(word) || MoneroMnemonic.isValid(word: word) {
                type = .correct
            } else if wordList.contains(where: { $0.hasPrefix(word) }) || MoneroMnemonic.isValid(word: word, partial: true) {
                type = .correctPrefix
            } else {
                type = .incorrect
            }

            return WordItem(word: word, range: match.range, type: type)
        }
    }

    private func possibleMnemonicWords(string: String) -> [String] {
        wordList.filter { $0.hasPrefix(string) } + MoneroMnemonic.suggestions(prefix: string)
    }

    private func hasCursor(item: WordItem) -> Bool {
        cursorOffset >= item.range.lowerBound && cursorOffset <= item.range.upperBound
    }

    private var cursorItem: WordItem? {
        mnemonicItems.first { hasCursor(item: $0) }
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
            case .correctPrefix: return !hasCursor(item: item)
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
            if words.count == MoneroMnemonic.wordCount {
                // 25 words can only be a Monero legacy seed: BIP39 tops out at 24
                accountType = try resolveMoneroAccountType(words: words)
            } else {
                accountType = try resolveAccountType(words: words)
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
