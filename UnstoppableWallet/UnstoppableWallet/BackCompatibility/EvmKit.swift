import Foundation
import Combine
import RxSwift
import BigInt
import HsToolKit
import EvmKit

extension Kit {

    struct DisposedError: Error {}

    public var lastBlockHeightObservable: Observable<Int> {
        lastBlockHeightPublisher.asObservable()
    }

    public var syncStateObservable: Observable<SyncState> {
        syncStatePublisher.asObservable()
    }

    public var transactionsSyncStateObservable: Observable<SyncState> {
        transactionsSyncStatePublisher.asObservable()
    }

    public var accountStateObservable: Observable<AccountState> {
        accountStatePublisher.asObservable()
    }

    public var allTransactionsObservable: Observable<([FullTransaction], Bool)> {
        allTransactionsPublisher.asObservable()
    }

    public func transactionSingle(hash: Data) -> Single<FullTransaction> {
        Single<FullTransaction>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.fetchTransaction(hash: hash)
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

    public func transactionsObservable(tagQueries: [TransactionTagQuery]) -> Observable<[FullTransaction]> {
        transactionsPublisher(tagQueries: tagQueries).asObservable()
    }

    public func transactionsSingle(tagQueries: [TransactionTagQuery], fromHash: Data? = nil, limit: Int? = nil) -> Single<[FullTransaction]> {
        Single.just(transactions(tagQueries: tagQueries, fromHash: fromHash, limit: limit))
    }

    public func rawTransaction(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int, nonce: Int? = nil) -> Single<RawTransaction> {
        rawTransaction(address: transactionData.to, value: transactionData.value, transactionInput: transactionData.input, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
    }

    public func rawTransaction(address: EvmKit.Address, value: BigUInt, transactionInput: Data = Data(), gasPrice: GasPrice, gasLimit: Int, nonce: Int? = nil) -> Single<RawTransaction> {
        Single<RawTransaction>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.fetchRawTransaction(address: address, value: value, transactionInput: transactionInput, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
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

    public func nonceSingle(defaultBlockParameter: DefaultBlockParameter) -> Single<Int> {
        Single<Int>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.nonce(defaultBlockParameter: defaultBlockParameter)
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

    public func sendSingle(rawTransaction: RawTransaction, signature: Signature) -> Single<FullTransaction> {
        Single<FullTransaction>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.send(rawTransaction: rawTransaction, signature: signature)
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

    public func getStorageAt(contractAddress: EvmKit.Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Data> {
        Single<Data>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.fetchStorageAt(contractAddress: contractAddress, positionData: positionData, defaultBlockParameter: defaultBlockParameter)
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

    public func call(contractAddress: EvmKit.Address, data: Data, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Data> {
        Single<Data>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.fetchCall(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter)
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

    public func estimateGas(to: EvmKit.Address?, amount: BigUInt, gasPrice: GasPrice) -> Single<Int> {
        Single<Int>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.fetchEstimateGas(to: to, amount: amount, gasPrice: gasPrice)
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

    public func estimateGas(to: EvmKit.Address?, amount: BigUInt?, gasPrice: GasPrice, data: Data?) -> Single<Int> {
        Single<Int>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.fetchEstimateGas(to: to, amount: amount, gasPrice: gasPrice, data: data)
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

    public func estimateGas(transactionData: TransactionData, gasPrice: GasPrice) -> Single<Int> {
        estimateGas(to: transactionData.to, amount: transactionData.value, gasPrice: gasPrice, data: transactionData.input)
    }

    public static func callSingle(networkManager: NetworkManager, rpcSource: RpcSource, contractAddress: EvmKit.Address, data: Data, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Data> {
        Single<Data>.create { observer in
            let task = Task {
                do {
                    let result = try await Kit.call(networkManager: networkManager, rpcSource: rpcSource, contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter)
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

extension L1FeeProvider {

    struct DisposedError: Error {}

    public func getL1Fee(gasPrice: GasPrice, gasLimit: Int, to: EvmKit.Address, value: BigUInt, data: Data) -> Single<BigUInt> {
        Single<BigUInt>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.l1Fee(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: data)
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

extension LegacyGasPriceProvider {

    struct DisposedError: Error {}

    public func gasPriceSingle() -> Single<Int> {
        Single<Int>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.gasPrice()
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

extension Eip1155Provider {

    struct DisposedError: Error {}

    public func getBalanceOf(contractAddress: EvmKit.Address, tokenId: BigUInt, address: EvmKit.Address) -> Single<BigUInt> {
        Single<BigUInt>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.balanceOf(contractAddress: contractAddress, tokenId: tokenId, address: address)
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

extension EIP1559GasPriceProvider {

    struct DisposedError: Error {}

    public func feeHistoryObservable(blocksCount: Int, defaultBlockParameter: DefaultBlockParameter = .latest, rewardPercentile: [Int]) -> Observable<FeeHistory> {
        feeHistoryPublisher(blocksCount: blocksCount, defaultBlockParameter: defaultBlockParameter, rewardPercentile: rewardPercentile).asObservable()
    }

    public func feeHistorySingle(blocksCount: Int, defaultBlockParameter: DefaultBlockParameter = .latest, rewardPercentile: [Int]) -> Single<FeeHistory> {
        Single<FeeHistory>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.feeHistory(blocksCount: blocksCount, defaultBlockParameter: defaultBlockParameter, rewardPercentile: rewardPercentile)
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

extension ENSProvider {

    struct DisposedError: Error {}

    public func address(domain: String) -> Single<EvmKit.Address> {
        Single<EvmKit.Address>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.resolveAddress(domain: domain)
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
