import Foundation
import RxSwift

public protocol IStorage {
    var nonSyncedBlocksInsertSubject: PublishSubject<Void> { get }

    func getFirstBlockInChain() -> Block?
    func getLastBlockInChain() -> Block?
    func getLastBlockInChain(afterBlock: Block) -> Block?
    func getBlockInChain(withHeight height: Int) -> Block?
    func getNonSyncedBlockHeaderHashes() -> [Data]
    func getBlock(byHeaderHash headerHash: Data) -> Block?

    func getBalances() -> Observable<DatabaseChangeSet<Balance>>
    func getExchangeRates() -> Observable<DatabaseChangeSet<ExchangeRate>>
    func getTransactionRecords() -> Observable<DatabaseChangeSet<TransactionRecord>>
}
