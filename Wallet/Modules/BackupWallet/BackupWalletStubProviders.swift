import Foundation
import BitcoinKit
import Darwin

class WalletManager: BackupWalletWordsProviderProtocol {
    func getWords() -> [String] {
        return ["burden", "swap", "fabric", "book", "palm", "main", "salute", "raw", "core", "reflect", "parade", "tone"]
        //        return (try? Mnemonic.generate()) ?? []
    }
}

class RandomProvider: BackupWalletRandomIndexesProviderProtocol {
    func getRandomIndexes(count: Int) -> [Int] {
        var indexes = [Int]()

        while indexes.count < count {
            let index = Int(arc4random_uniform(12) + 1)
            if !indexes.contains(index) {
                indexes.append(index)
            }
        }

        return indexes
    }
}
