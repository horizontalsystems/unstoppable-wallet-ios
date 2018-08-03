import Foundation
import RxSwift

protocol ILocalStorage: class {
    var savedWords: [String]? { get }
    func save(words: [String])
    func clearWords()
}

public protocol IStorage {
    func getFirstBlockInChain() -> Block?
    func getLastBlockInChain() -> Block?
    func getLastBlockInChain(afterBlock: Block) -> Block?
    func getBlockInChain(withHeight height: Int) -> Block?

    func getBalances() -> Observable<DatabaseChangeSet<Balance>>
    func getExchangeRates() -> Observable<DatabaseChangeSet<ExchangeRate>>
    func getTransactionRecords() -> Observable<DatabaseChangeSet<TransactionRecord>>
}

public class WalletKitProvider {
    public static let shared = WalletKitProvider()

    public var storage: IStorage {
        return RealmStorage.shared
    }

}
