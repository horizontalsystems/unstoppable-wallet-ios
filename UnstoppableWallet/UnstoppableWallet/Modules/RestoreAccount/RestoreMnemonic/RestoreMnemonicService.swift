import Foundation
import HdWalletKit
import RxSwift
import RxRelay

class RestoreMnemonicService {
    private let wordList: [String]
    private let passphraseEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let passphraseValidator: PassphraseValidator

    var passphrase: String = ""
    let defaultName: String
    private var name: String = ""

    init(accountFactory: AccountFactory, passphraseValidator: PassphraseValidator) {
        self.passphraseValidator = passphraseValidator

        wordList = Mnemonic.Language.allCases.reduce([String]()) { array, language in
            var array = array
            array.append(contentsOf: Mnemonic.wordList(for: language).map(String.init))
            return array
        }

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

    enum RestoreError: Error {
        case emptyPassphrase
    }

    enum ErrorList: Error {
        case errors([Error])
    }

}
