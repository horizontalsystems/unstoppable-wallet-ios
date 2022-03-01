import EthereumKit
import RxSwift
import BigInt
import HsToolKit

class BaseEvmAdapter {
    static let confirmationsThreshold = 12

    let evmKitWrapper: EvmKitWrapper
    let decimals: Int

    init(evmKitWrapper: EvmKitWrapper, decimals: Int) {
        self.evmKitWrapper = evmKitWrapper
        self.decimals = decimals
    }

    var evmKit: EthereumKit.Kit {
        evmKitWrapper.evmKit
    }

    func balanceDecimal(kitBalance: BigUInt?, decimals: Int) -> Decimal {
        guard let kitBalance = kitBalance else {
            return 0
        }

        guard let significand = Decimal(string: kitBalance.description) else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -decimals, significand: significand)
    }

    func convertToAdapterState(evmSyncState: EthereumKit.SyncState) -> AdapterState {
        switch evmSyncState {
            case .synced: return .synced
            case .notSynced(let error): return .notSynced(error: error.convertedError)
            case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    var isMainNet: Bool {
        evmKitWrapper.evmKit.chain.isMainNet
    }

    func balanceData(balance: BigUInt?) -> BalanceData {
        BalanceData(balance: balanceDecimal(kitBalance: balance, decimals: decimals))
    }

}

// IAdapter
extension BaseEvmAdapter {

    var statusInfo: [(String, Any)] {
        evmKit.statusInfo()
    }

    var debugInfo: String {
        evmKit.debugInfo
    }

}

// ITransactionsAdapter
extension BaseEvmAdapter {

    var lastBlockInfo: LastBlockInfo? {
        evmKit.lastBlockHeight.map { LastBlockInfo(height: $0, timestamp: nil) }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        evmKit.lastBlockHeightObservable.map { _ in () }
    }

}

extension BaseEvmAdapter: IDepositAdapter {

    var receiveAddress: String {
        evmKit.receiveAddress.eip55
    }

}
