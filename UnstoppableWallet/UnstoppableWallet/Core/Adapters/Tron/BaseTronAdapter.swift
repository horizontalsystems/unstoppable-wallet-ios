import Foundation
import TronKit
import RxSwift
import BigInt
import HsToolKit

class BaseTronAdapter {
    static let confirmationsThreshold = 18

    let tronKitWrapper: TronKitWrapper
    let decimals: Int

    init(tronKitWrapper: TronKitWrapper, decimals: Int) {
        self.tronKitWrapper = tronKitWrapper
        self.decimals = decimals
    }

    var tronKit: TronKit.Kit {
        tronKitWrapper.tronKit
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

    func convertToAdapterState(tronSyncState: TronKit.SyncState) -> AdapterState {
        switch tronSyncState {
            case .synced: return .synced
            case .notSynced(let error): return .notSynced(error: error.convertedError)
            case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    var isMainNet: Bool {
        tronKitWrapper.tronKit.network == .mainNet
    }

    func balanceData(balance: BigUInt?) -> BalanceData {
        BalanceData(available: balanceDecimal(kitBalance: balance, decimals: decimals))
    }

    func accountActive(address: TronKit.Address) async -> Bool {
        return (try? await tronKit.accountActive(address: address)) ?? true
    }

}

// IAdapter
extension BaseTronAdapter {

    var statusInfo: [(String, Any)] {
        []
    }

    var debugInfo: String {
        ""
    }

}

// ITransactionsAdapter
extension BaseTronAdapter {

    var lastBlockInfo: LastBlockInfo? {
        tronKit.lastBlockHeight.map { LastBlockInfo(height: $0, timestamp: nil) }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        tronKit.lastBlockHeightPublisher.asObservable().map { _ in () }
    }

}

extension BaseTronAdapter: IDepositAdapter {

    var receiveAddress: DepositAddress {
        ActivatedDepositAddress(
            receiveAddress: tronKit.receiveAddress.base58,
            isActive: tronKit.accountActive
        )
    }

}
