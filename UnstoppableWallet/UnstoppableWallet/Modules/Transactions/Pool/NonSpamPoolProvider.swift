import Foundation
import RxSwift
import RxRelay

class NonSpamPoolProvider {
    private let poolProvider: PoolProvider

    init(poolProvider: PoolProvider) {
        self.poolProvider = poolProvider
    }

    private func single(from: TransactionRecord?, limit: Int, transactions: [TransactionRecord] = []) -> Single<[TransactionRecord]> {
//        let extendedLimit = limit * 2
        let extendedLimit = limit

        return poolProvider.recordsSingle(from: from, limit: extendedLimit)
                .flatMap { [weak self] newTransactions in
                    let allTransactions = transactions + newTransactions
                    let nonSpamTransactions = allTransactions.filter { !$0.spam }

                    if nonSpamTransactions.count >= limit || newTransactions.count < extendedLimit {
                        return Single.just(Array(nonSpamTransactions.prefix(limit)))
                    } else {
                        return self?.single(from: allTransactions.last, limit: limit, transactions: allTransactions) ?? Single.just([])
                    }
                }
    }

}

extension NonSpamPoolProvider {

    var syncing: Bool {
        poolProvider.syncing
    }

    var syncingObservable: Observable<Bool> {
        poolProvider.syncingObservable
    }

    var lastBlockInfo: LastBlockInfo? {
        poolProvider.lastBlockInfo
    }

    func recordsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        single(from: from, limit: limit)
    }

    func recordsObservable() -> Observable<[TransactionRecord]> {
        poolProvider.recordsObservable()
                .map { transactions in
                    transactions.filter { !$0.spam }
                }
    }

    func lastBlockUpdatedObservable() -> Observable<Void> {
        poolProvider.lastBlockUpdatedObservable()
    }

}
