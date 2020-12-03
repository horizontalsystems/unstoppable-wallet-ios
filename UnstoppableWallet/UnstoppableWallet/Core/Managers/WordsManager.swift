import HdWalletKit

class WordsManager {
}

extension WordsManager: IWordsManager {

    func generateWords(count: Int) throws -> [String] {
        try Mnemonic.generate(wordCount: count == 24 ? .twentyFour : .twelve)
    }

}
