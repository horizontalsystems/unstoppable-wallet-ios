import Foundation

protocol ILocalStorage: class {
    var savedWords: [String]? { get }
    func save(words: [String])
    func clearWords()
}

public class WalletKitProvider {
    public static let shared = WalletKitProvider()

    public var storage: IStorage {
        return RealmStorage.shared
    }

}
