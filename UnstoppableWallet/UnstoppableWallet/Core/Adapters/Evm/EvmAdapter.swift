import EvmKit
import RxSwift
import BigInt
import HsToolKit
import Eip20Kit
import UniswapKit

class EvmAdapter: BaseEvmAdapter {
    static let decimals = 18

    init(evmKitWrapper: EvmKitWrapper) {
        super.init(evmKitWrapper: evmKitWrapper, decimals: EvmAdapter.decimals)
    }

}

extension EvmAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try EvmKit.Kit.clear(exceptFor: excludedWalletIds)
    }

}

// IAdapter
extension EvmAdapter: IAdapter {

    func start() {
        // started via EvmKitManager
    }

    func stop() {
        // stopped via EvmKitManager
    }

    func refresh() {
        // refreshed via EvmKitManager
    }

}

extension EvmAdapter: IBalanceAdapter {

    var balanceState: AdapterState {
        convertToAdapterState(evmSyncState: evmKit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        evmKit.syncStateObservable.map { [weak self] in
            self?.convertToAdapterState(evmSyncState: $0) ?? .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    var balanceData: BalanceData {
        balanceData(balance: evmKit.accountState?.balance)
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        evmKit.accountStateObservable.map { [weak self] in
            self?.balanceData(balance: $0.balance) ?? BalanceData(balance: 0)
        }
    }

}

extension EvmAdapter: ISendEthereumAdapter {

    func transactionData(amount: BigUInt, address: EvmKit.Address) -> TransactionData {
        evmKit.transferTransactionData(to: address, value: amount)
    }

}
