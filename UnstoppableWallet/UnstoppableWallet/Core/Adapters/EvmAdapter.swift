import EthereumKit
import RxSwift
import BigInt
import HsToolKit
import Erc20Kit
import UniswapKit

class EvmAdapter: BaseEvmAdapter {
    static let decimal = 18

    init(evmKit: EthereumKit.Kit, coinManager: ICoinManager) {
        super.init(evmKit: evmKit, decimal: EvmAdapter.decimal, coinManager: coinManager)
    }

}

extension EvmAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try EthereumKit.Kit.clear(exceptFor: excludedWalletIds)
    }

}

// IAdapter
extension EvmAdapter: IAdapter {

    func start() {
        // started via EthereumKitManager
    }

    func stop() {
        // stopped via EthereumKitManager
    }

    func refresh() {
        evmKit.refresh()
    }

}

extension EvmAdapter: IBalanceAdapter {

    var balanceState: AdapterState {
        convertToAdapterState(evmSyncState: evmKit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        evmKit.syncStateObservable.map { [unowned self] in self.convertToAdapterState(evmSyncState: $0) }
    }

    var balanceData: BalanceData {
        balanceData(balance: evmKit.accountState?.balance)
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        evmKit.accountStateObservable.map { [unowned self] in self.balanceData(balance: $0.balance) }
    }

}

extension EvmAdapter: ISendEthereumAdapter {

    func transactionData(amount: BigUInt, address: EthereumKit.Address) -> TransactionData {
        evmKit.transferTransactionData(to: address, value: amount)
    }

}

extension EvmAdapter: ITransactionsAdapter {

    var transactionState: AdapterState {
        convertToAdapterState(evmSyncState: evmKit.transactionsSyncState)
    }

    var transactionStateUpdatedObservable: Observable<Void> {
        evmKit.transactionsSyncStateObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        evmKit.etherTransactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        evmKit.etherTransactionsSingle(fromHash: from.flatMap { Data(hex: $0.transactionHash) }, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionConverter.transactionRecord(fromTransaction: $0) }
                }
    }

    func rawTransaction(hash: String) -> String? {
        nil
    }

}
