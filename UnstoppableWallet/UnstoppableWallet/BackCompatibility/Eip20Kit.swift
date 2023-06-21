import Foundation
import Combine
import RxSwift
import BigInt
import EvmKit
import HsToolKit
import Eip20Kit

extension Eip20Kit.Kit {
    struct DisposedError: Error {}

    public func transactionsSingle(from hash: Data?, limit: Int?) throws -> Single<[FullTransaction]> {
        Single.just(transactions(from: hash, limit: limit))
    }

    public var syncStateObservable: Observable<SyncState> {
        syncStatePublisher.asObservable()
    }

    public var transactionsSyncStateObservable: Observable<SyncState> {
        transactionsSyncStatePublisher.asObservable()
    }

    public var balanceObservable: Observable<BigUInt> {
        balancePublisher.asObservable()
    }

    public var transactionsObservable: Observable<[FullTransaction]> {
        transactionsPublisher.asObservable()
    }

    public func allowanceSingle(spenderAddress: EvmKit.Address, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<String> {
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

    public static func tokenInfoSingle(networkManager: NetworkManager, rpcSource: RpcSource, contractAddress: EvmKit.Address) -> Single<TokenInfo> {
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
