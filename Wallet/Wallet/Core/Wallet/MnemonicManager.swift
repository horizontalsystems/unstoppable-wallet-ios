import Foundation
import BitcoinKit

class MnemonicManager: MnemonicProtocol {

    func generateWords() -> [String] {
        return (try? Mnemonic.generate()) ?? []
    }

    func validate(words: [String]) -> Bool {
        let set = Set(words)

        guard set.count == 12 else {
            return false
        }

        let wordsList = MnemonicWordsList.english.map(String.init)

        for word in set {
            if word == "" || !wordsList.contains(word) {
                return false
            }
        }

        return true
    }

}
