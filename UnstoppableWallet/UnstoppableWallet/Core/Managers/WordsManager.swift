import HdWalletKit

class WordsManager {
}

extension WordsManager: IWordsManager {

    func generateWords(count: Int) throws -> [String] {
        try Mnemonic.generate(strength: count == 24 ? .veryHigh : .default)
    }

    func validate(words: [String], requiredWordsCount: Int) throws {
        try Mnemonic.validate(words: words, strength: requiredWordsCount == 24 ? .veryHigh : .default)
    }

}
