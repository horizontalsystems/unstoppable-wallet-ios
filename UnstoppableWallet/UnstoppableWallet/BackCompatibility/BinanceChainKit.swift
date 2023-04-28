import Foundation
import Combine
import RxSwift
import HsExtensions
import BinanceChainKit

extension BinanceChainKit {

    struct DisposedError: Error {}

    public var lastBlockHeightObservable: Observable<Int?> {
        $lastBlockHeight.asObservable()
    }

    public var syncStateObservable: Observable<SyncState> {
        $syncState.asObservable()
    }

    public func transactionsSingle(symbol: String, filterType: TransactionFilterType? = nil, fromTransactionHash: String? = nil, limit: Int? = nil) -> Single<[TransactionInfo]> {
        Single.just(transactions(symbol: symbol, filterType: filterType, fromTransactionHash: fromTransactionHash, limit: limit))
    }

    public func sendSingle(symbol: String, to: String, amount: Decimal, memo: String) -> Single<String> {
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

    public func moveToBSCSingle(symbol: String, amount: Decimal) -> Single<String> {
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

extension Asset {

    public var balanceObservable: Observable<Decimal> {
        $balance.asObservable()
    }

    public func transactionsObservable(filterType: TransactionFilterType? = nil) -> Observable<[TransactionInfo]> {
        transactionsPublisher(filterType: filterType).asObservable()
    }

}
