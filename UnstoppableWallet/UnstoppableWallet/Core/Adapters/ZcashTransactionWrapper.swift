import Foundation
import ZcashLightClientKit
import HsExtensions

class ZcashTransactionWrapper {
    let id: String?
    let raw: Data?
    let transactionHash: String
    let transactionIndex: Int
    let toAddress: String?
    let isSentTransaction: Bool
    let expiryHeight: Int?
    let minedHeight: Int?
    let timestamp: TimeInterval
    let value: Zatoshi
    let memo: String?
    let failed: Bool

    init?(confirmedTransaction: ZcashTransaction.Overview, memo: Memo?) {
        id = confirmedTransaction.id.description
        raw = confirmedTransaction.raw
        transactionHash = confirmedTransaction.rawID.hs.reversedHex
        transactionIndex = confirmedTransaction.index ?? 0
        toAddress = nil
        isSentTransaction = confirmedTransaction.value < Zatoshi(0)
        minedHeight = confirmedTransaction.minedHeight
        expiryHeight = confirmedTransaction.expiryHeight
        timestamp = confirmedTransaction.blockTime ?? 0
        value = confirmedTransaction.value
        self.memo = memo.flatMap { $0.toString() }
        failed = false
    }

    init?(pendingTransaction: PendingTransactionEntity) {
        guard let rawTransactionId = pendingTransaction.rawTransactionId else {
            return nil
        }

        id = pendingTransaction.id?.description
        raw = pendingTransaction.raw
        transactionHash = rawTransactionId.hs.reversedHex
        transactionIndex = -1
        toAddress = pendingTransaction.recipient.asString

        // if has toAddress - we must mark tx as sent
        isSentTransaction = toAddress == nil ? pendingTransaction.value < Zatoshi(0) : true
        minedHeight = nil
        expiryHeight = pendingTransaction.expiryHeight
        timestamp = pendingTransaction.createTime
        value = pendingTransaction.value
        memo = pendingTransaction.memo.flatMap { String(bytes: $0, encoding: .utf8) }
        failed = pendingTransaction.isFailure
    }

}

/// This would mean that a pending transaction with nil `toAddress` is a shielding transaction to the user's own account
extension PendingTransactionRecipient {
    var asString: String? {
        switch self {
        case .address(let recipient):
            return recipient.stringEncoded
        default:
            return nil
        }
    }
}

extension ZcashTransactionWrapper: Comparable {

    public static func <(lhs: ZcashTransactionWrapper, rhs: ZcashTransactionWrapper) -> Bool {
        if lhs.timestamp != rhs.timestamp {
            return lhs.timestamp > rhs.timestamp
        } else {
            return lhs.transactionIndex > rhs.transactionIndex
        }
    }

    public static func ==(lhs: ZcashTransactionWrapper, rhs: ZcashTransactionWrapper) -> Bool {
        lhs.transactionHash == rhs.transactionHash
    }

}

extension ZcashTransactionWrapper: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(transactionHash)
    }

}

extension ZcashTransactionWrapper {

    var description: String {
        "TX(Zcash) === hash:\(transactionHash) : \(toAddress?.prefix(6) ?? "N/A") : \(transactionIndex) height: \(minedHeight?.description ?? "N/A") timestamp \(timestamp.description)"
    }

}
