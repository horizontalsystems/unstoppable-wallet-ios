import Foundation

protocol WalletDataProviderProtocol {
    var walletData: WalletData { get }
}

protocol LocalStorageProtocol {
    var savedWords: [String]? { get }
    func save(words: [String])
}

protocol MnemonicProtocol {
    func generateWords() -> [String]
}
