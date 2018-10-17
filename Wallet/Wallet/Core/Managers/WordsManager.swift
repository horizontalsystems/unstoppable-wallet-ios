import HSHDWalletKit
import RxSwift

class WordsManager {
    private let secureStorage: ISecureStorage
    private let localStorage: ILocalStorage

    var backedUpSubject: PublishSubject<Bool> = PublishSubject()
    private(set) var words: [String]?

    init(secureStorage: ISecureStorage, localStorage: ILocalStorage) {
        self.secureStorage = secureStorage
        self.localStorage = localStorage

        words = secureStorage.words
    }

}

extension WordsManager: IWordsManager {

    var isBackedUp: Bool {
        get {
            return localStorage.isBackedUp
        }
        set {
            localStorage.isBackedUp = newValue
            backedUpSubject.onNext(newValue)
        }
    }

    var isLoggedIn: Bool {
        return words != nil
    }

    func createWords() throws {
        let generatedWords = try Mnemonic.generate()
        try secureStorage.set(words: generatedWords)
        words = generatedWords
    }

    func validate(words: [String]) throws {
        try Mnemonic.validate(words: words)
    }

    func restore(withWords words: [String]) throws {
        try Mnemonic.validate(words: words)
        try secureStorage.set(words: words)
        self.words = words
    }

    func removeWords() {
        words = nil
        try? secureStorage.set(words: nil)
    }

}
