import Foundation
import WalletKit

class WordsManager {
    static let shared = WordsManager()

    let localStorage: ILocalStorage

    var words: [String]?

    var hasWords: Bool {
        return words != nil
    }

    init(localStorage: ILocalStorage = UserDefaultsStorage.shared) {
        self.localStorage = localStorage

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
