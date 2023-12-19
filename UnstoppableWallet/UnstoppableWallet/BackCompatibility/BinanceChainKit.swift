import BinanceChainKit
import Combine
import Foundation
import HsExtensions
import RxSwift

public extension BinanceChainKit {
    internal struct DisposedError: Error {}

    var lastBlockHeightObservable: Observable<Int?> {
        $lastBlockHeight.asObservable()
    }

    var syncStateObservable: Observable<SyncState> {
        $syncState.asObservable()
    }

    func transactionsSingle(symbol: String, filterType: TransactionFilterType? = nil, fromTransactionHash: String? = nil, limit: Int? = nil) -> Single<[TransactionInfo]> {
        Single.just(transactions(symbol: symbol, filterType: filterType, fromTransactionHash: fromTransactionHash, limit: limit))
    }

    func sendSingle(symbol: String, to: String, amount: Decimal, memo: String) -> Single<String> {
        Single<String>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let hash = try await strongSelf.send(symbol: symbol, to: to, amount: amount, memo: memo)
                    observer(.success(hash))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func moveToBSCSingle(symbol: String, amount: Decimal) -> Single<String> {
        Single<String>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let hash = try await strongSelf.moveToBSC(symbol: symbol, amount: amount)
                    observer(.success(hash))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
}

public extension Asset {
    var balanceObservable: Observable<Decimal> {
        $balance.asObservable()
    }

    func transactionsObservable(filterType: TransactionFilterType? = nil) -> Observable<[TransactionInfo]> {
        transactionsPublisher(filterType: filterType).asObservable()
    }
}
