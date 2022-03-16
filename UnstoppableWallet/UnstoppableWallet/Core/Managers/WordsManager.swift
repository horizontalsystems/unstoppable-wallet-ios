import HdWalletKit

class WordsManager {

    func generateWords(count: Int) throws -> [String] {
        try Mnemonic.generate(wordCount: count == 24 ? .twentyFour : .twelve)
    }

}
