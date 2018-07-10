import Foundation
import WalletKit

class MnemonicManager: IMnemonic {

    enum ValidationError: Error {
        case invalidWordsCount
        case invalidWords
    }

    func generateWords() throws -> [String] {
        return try Mnemonic.generate()
    }

    func validate(words: [String]) throws {
        let set = Set(words)

        guard set.count == 12 else {
            throw ValidationError.invalidWordsCount
        }

        let wordsList = WordList.english.map(String.init)

        for word in set {
            if word == "" || !wordsList.contains(word) {
                throw ValidationError.invalidWords
            }
        }
    }

}
