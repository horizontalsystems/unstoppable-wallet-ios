import BigInt
import Combine
import EvmKit
import Foundation
import HsToolKit
import RxSwift

public extension Kit {
    internal struct DisposedError: Error {}

    var lastBlockHeightObservable: Observable<Int> {
        lastBlockHeightPublisher.asObservable()
    }

    var syncStateObservable: Observable<SyncState> {
        syncStatePublisher.asObservable()
    }

    var transactionsSyncStateObservable: Observable<SyncState> {
        transactionsSyncStatePublisher.asObservable()
    }

    var accountStateObservable: Observable<AccountState> {
        accountStatePublisher.asObservable()
    }

    var allTransactionsObservable: Observable<([FullTransaction], Bool)> {
        allTransactionsPublisher.asObservable()
    }

    func transactionSingle(hash: Data) -> Single<FullTransaction> {
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

    func transactionsObservable(tagQueries: [TransactionTagQuery]) -> Observable<[FullTransaction]> {
        transactionsPublisher(tagQueries: tagQueries).asObservable()
    }

    func transactionsSingle(tagQueries: [TransactionTagQuery], fromHash: Data? = nil, limit: Int? = nil) -> Single<[FullTransaction]> {
        Single.just(transactions(tagQueries: tagQueries, fromHash: fromHash, limit: limit))
    }

    func rawTransaction(transactionData: TransactionData, gasPrice: GasPrice, gasLimit: Int, nonce: Int? = nil) -> Single<RawTransaction> {
        rawTransaction(address: transactionData.to, value: transactionData.value, transactionInput: transactionData.input, gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
    }

    func rawTransaction(address: EvmKit.Address, value: BigUInt, transactionInput: Data = Data(), gasPrice: GasPrice, gasLimit: Int, nonce: Int? = nil) -> Single<RawTransaction> {
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

    func nonceSingle(defaultBlockParameter: DefaultBlockParameter) -> Single<Int> {
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

    func sendSingle(rawTransaction: RawTransaction, signature: Signature) -> Single<FullTransaction> {
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

    func getStorageAt(contractAddress: EvmKit.Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Data> {
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

    func call(contractAddress: EvmKit.Address, data: Data, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Data> {
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

    func estimateGas(to: EvmKit.Address?, amount: BigUInt, gasPrice: GasPrice) -> Single<Int> {
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

    func estimateGas(to: EvmKit.Address?, amount: BigUInt?, gasPrice: GasPrice, data: Data?) -> Single<Int> {
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

    func estimateGas(transactionData: TransactionData, gasPrice: GasPrice) -> Single<Int> {
        estimateGas(to: transactionData.to, amount: transactionData.value, gasPrice: gasPrice, data: transactionData.input)
    }

    static func callSingle(networkManager: NetworkManager, rpcSource: RpcSource, contractAddress: EvmKit.Address, data: Data, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Data> {
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

    public func gasPriceSingle() -> Single<GasPrice> {
        Single<GasPrice>.create { [weak self] observer in
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

public extension EIP1559GasPriceProvider {
    internal struct DisposedError: Error {}

    func gasPriceSingle(defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<GasPrice> {
        Single<GasPrice>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.gasPrice(defaultBlockParameter: defaultBlockParameter)
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
