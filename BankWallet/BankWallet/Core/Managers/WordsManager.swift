import HSHDWalletKit
import RxSwift

class WordsManager {
    private let localStorage: ILocalStorage

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

}

extension WordsManager: IWordsManager {

    func generateWords(count: Int) throws -> [String] {
        return try Mnemonic.generate(strength: count == 24 ? .veryHigh : .default)
    }

    func validate(words: [String]) throws {
        try Mnemonic.validate(words: words, strength: words.count == 24 ? .veryHigh : .default)
    }

}
