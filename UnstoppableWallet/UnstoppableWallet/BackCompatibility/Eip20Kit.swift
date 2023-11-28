import BigInt
import Combine
import Eip20Kit
import EvmKit
import Foundation
import HsToolKit
import RxSwift

public extension Eip20Kit.Kit {
    internal struct DisposedError: Error {}

    func transactionsSingle(from hash: Data?, limit: Int?) throws -> Single<[FullTransaction]> {
        Single.just(transactions(from: hash, limit: limit))
    }

    var syncStateObservable: Observable<SyncState> {
        syncStatePublisher.asObservable()
    }

    var transactionsSyncStateObservable: Observable<SyncState> {
        transactionsSyncStatePublisher.asObservable()
    }

    var balanceObservable: Observable<BigUInt> {
        balancePublisher.asObservable()
    }

    var transactionsObservable: Observable<[FullTransaction]> {
        transactionsPublisher.asObservable()
    }

    func allowanceSingle(spenderAddress: EvmKit.Address, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<String> {
        Single<String>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.allowance(spenderAddress: spenderAddress, defaultBlockParameter: defaultBlockParameter)
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    static func tokenInfoSingle(networkManager: NetworkManager, rpcSource: RpcSource, contractAddress: EvmKit.Address) -> Single<TokenInfo> {
        Single<TokenInfo>.create { observer in
            let task = Task {
                do {
                    let result = try await Self.tokenInfo(networkManager: networkManager, rpcSource: rpcSource, contractAddress: contractAddress)
                    observer(.success(result))
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
