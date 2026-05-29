import BigInt
import Foundation
import HsToolKit
import RxSwift
import TronKit

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

    /// `true` for on-chain-active accounts AND for gas-token-payment accounts (passkey-AA / GasFree)
    /// whose wallet may not be on-chain yet but still semantically usable for receive/send via the
    /// abstraction layer. Use this for UI activation cues, not raw `tronKit.accountActive`.
    var effectiveAccountActive: Bool {
        tronKit.accountActive || tronKitWrapper.gasTokenPayment
    }

    /// Single source for `effectiveAccountActive` updates. Subclasses' `cautionUpdatedObservable`
    /// and any UI-facing publisher should subscribe to this rather than re-deriving the OR.
    var effectiveAccountActivePublisher: Observable<Bool> {
        let gasTokenPayment = tronKitWrapper.gasTokenPayment
        return tronKit.accountActivePublisher.asObservable().map { $0 || gasTokenPayment }
    }

    func balanceDecimal(kitBalance: BigUInt?, decimals: Int) -> Decimal {
        guard let kitBalance else {
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
        case let .notSynced(error): return .notSynced(error: error.convertedError.localizedDescription)
        case .syncing: return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        }
    }

    var isMainNet: Bool {
        tronKitWrapper.tronKit.network == .mainNet
    }

    func balanceData(balance: BigUInt?) -> BalanceData {
        BalanceData(balance: balanceDecimal(kitBalance: balance, decimals: decimals))
    }

    func accountActive(address: TronKit.Address) async -> Bool {
        await (try? tronKit.accountActive(address: address)) ?? true
    }

    func balanceCaution(active: Bool) -> CautionNew? {
        if !active {
            return .init(text: "not_activated".localized, type: .warning)
        }

        return nil
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
            isActive: effectiveAccountActive
        )
    }
}

public extension Array where Array.Element == Fee {
    func calculateTotalFees() -> Int {
        var totalFees = 0
        for fee in self {
            switch fee {
            case let .bandwidth(points, price):
                totalFees += points * price
            case let .energy(required, price):
                totalFees += required * price
            case let .accountActivation(amount):
                totalFees += amount
            }
        }

        return totalFees
    }
}
