import Combine
import Foundation
import HdWalletKit

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
    @Published var passphraseEnabled = false
    @Published var wordListLanguage: String = ""
    @Published var passphraseCaution: CautionState = .none

    @Published var advanced = false
    @Published var buttonEnabled = true

    private let proceedSubject = PassthroughSubject<(String, AccountType), Never>()
    private let replaceWordSubject = PassthroughSubject<(NSRange, String), Never>()
    private let clearPassphraseSubject = PassthroughSubject<Void, Never>()

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

    private func possibleMnemonicWords(string: String) -> [String] {
        wordList.filter { $0.hasPrefix(string) }
    }

    private func hasCursor(item: WordItem) -> Bool {
        cursorOffset >= item.range.lowerBound && cursorOffset <= item.range.upperBound
    }

    private var cursorItem: WordItem? {
        mnemonicItems.first { hasCursor(item: $0) }
    }

    private func clearInputs() {
        clearPassphraseSubject.send()
        passphraseCaution = .none
        passphrase = ""
    }

    private var resolvedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resolveAccountType(words: [String]) throws -> AccountType {
        var errors = [Error]()
        let passphrase = advanced ? passphrase : ""

        if advanced, passphraseEnabled, passphrase.isEmpty {
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

        return .mnemonic(
            words: words.map(\.decomposedStringWithCompatibilityMapping),
            salt: passphrase.decomposedStringWithCompatibilityMapping,
            bip39Compliant: true
        )
    }
}

// MARK: - Public interface

extension RestoreMnemonicViewModel {
    var proceedPublisher: AnyPublisher<(String, AccountType), Never> { proceedSubject.eraseToAnyPublisher() }
    var replaceWordPublisher: AnyPublisher<(NSRange, String), Never> { replaceWordSubject.eraseToAnyPublisher() }
    var clearPassphrasePublisher: AnyPublisher<Void, Never> { clearPassphraseSubject.eraseToAnyPublisher() }

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

    func onTogglePassphrase(isOn: Bool) {
        passphraseEnabled = isOn
        clearInputs()
    }

    func onChange(passphrase: String) {
        self.passphrase = passphrase
        passphraseCaution = .none
    }

    func onTapProceed() {
        mnemonicCaution = .none
        passphraseCaution = .none

        guard mnemonicItems.allSatisfy({ $0.type == .correct }) else {
            invalidRanges = mnemonicItems.filter { $0.type != .correct }.map(\.range)
            return
        }

        do {
            let accountType = try resolveAccountType(words: mnemonicItems.map(\.word))
            proceedSubject.send((resolvedName, accountType))
        } catch let ErrorList.errors(errors) {
            for error in errors {
                if case RestoreError.emptyPassphrase = error {
                    passphraseCaution = .caution(Caution(text: "restore.error.empty_passphrase".localized, type: .error))
                } else {
                    mnemonicCaution = .caution(Caution(text: error.convertedError.smartDescription, type: .error))
                }
            }
        } catch {}
    }
}

// MARK: - Types

extension RestoreMnemonicViewModel {
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
