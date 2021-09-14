import EthereumKit
import RxSwift
import BigInt
import HsToolKit

class BaseEvmAdapter {
    static let confirmationsThreshold = 12

    let evmKit: EthereumKit.Kit
    let decimal: Int

    init(evmKit: EthereumKit.Kit, decimal: Int) {
        self.evmKit = evmKit
        self.decimal = decimal
    }

    func balanceDecimal(kitBalance: BigUInt?, decimal: Int) -> Decimal {
        guard let kitBalance = kitBalance else {
            return 0
        }

        guard let significand = Decimal(string: kitBalance.description) else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -decimal, significand: significand)
    }

    func convertToAdapterState(evmSyncState: EthereumKit.SyncState) -> AdapterState {
        switch evmSyncState {
            case .synced: return .synced
            case .notSynced(let error): return .notSynced(error: error.convertedError)
            case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    var isMainNet: Bool {
        evmKit.networkType.isMainNet
    }

    func balanceData(balance: BigUInt?) -> BalanceData {
        BalanceData(balance: balanceDecimal(kitBalance: balance, decimal: decimal))
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
