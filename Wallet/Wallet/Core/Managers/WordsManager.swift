import Foundation
import WalletKit
import RxSwift

class WordsManager {
    static let shared = WordsManager()
    let backedUpKey = "backed_up_key"

    let localStorage: ILocalStorage

    let backedUpSubject: BehaviorSubject<Bool>
    var isBackedUp: Bool {
        get {
            let v: Bool = KeychainHelper.shared.getBool(backedUpKey) ?? false
            return v
        }
        set {
            backedUpSubject.onNext(newValue)
            try? KeychainHelper.shared.set(newValue, key: backedUpKey)
        }
    }

    var words: [String]?

    var hasWords: Bool {
        return words != nil
    }

    init(localStorage: ILocalStorage = UserDefaultsStorage.shared) {
        self.localStorage = localStorage
        backedUpSubject = BehaviorSubject(value: false)
        backedUpSubject.onNext(isBackedUp)

        words = localStorage.savedWords
    }

    func createWords() throws {
        let generatedWords = try Mnemonic.generate()
        localStorage.save(words: generatedWords)
        words = generatedWords
    }

    func restore(withWords words: [String]) throws {
        try Mnemonic.validate(words: words)
        localStorage.save(words: words)
        self.words = words
    }

    func removeWords() {
        words = nil
        localStorage.clearWords()
    }

}
