import Foundation

class WalletManager {

    func createWallet(withWords words: [String]) -> WalletWrapper {
        return WalletWrapper(words: words)
    }

}
