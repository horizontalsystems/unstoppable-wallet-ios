import Foundation
import BitcoinKit
import Darwin

class WalletManager: BackupWalletWordsProviderProtocol {

    static let words = (try? Mnemonic.generate()) ?? []

    func getWords() -> [String] {
        return WalletManager.words
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
