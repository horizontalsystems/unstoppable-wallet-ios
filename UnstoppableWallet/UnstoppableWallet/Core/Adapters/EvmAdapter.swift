import EthereumKit
import RxSwift
import BigInt
import HsToolKit
import Erc20Kit
import UniswapKit

class EvmAdapter: BaseEvmAdapter {
    static let decimals = 18

    init(evmKitWrapper: EvmKitWrapper) {
        super.init(evmKitWrapper: evmKitWrapper, decimals: EvmAdapter.decimals)
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
        // refreshed via EthereumKitManager
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
