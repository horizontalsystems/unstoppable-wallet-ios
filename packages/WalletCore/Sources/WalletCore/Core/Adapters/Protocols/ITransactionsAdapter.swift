import Foundation
import MarketKit
import RxSwift

public protocol ITransactionsAdapter {
    var syncing: Bool { get }
    var syncingObservable: Observable<Void> { get }
    var lastBlockInfo: LastBlockInfo? { get }
    var lastBlockUpdatedObservable: Observable<Void> { get }
    var explorerTitle: String { get }
    var additionalTokenQueries: [TokenQuery] { get }
    func explorerUrl(transactionHash: String) -> String?
    func transactionsObservable(token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?) -> Observable<[TransactionRecord]>
    func transactionsSingle(paginationData: String?, token: MarketKit.Token?, filter: TransactionTypeFilter, address: String?, limit: Int) -> Single<[TransactionRecord]>
    func allTransactionsAfter(paginationData: String?) -> Single<[TransactionRecord]>
    func rawTransaction(hash: String) -> String?
}
