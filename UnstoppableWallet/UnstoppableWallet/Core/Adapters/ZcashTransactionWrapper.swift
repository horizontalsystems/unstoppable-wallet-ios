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
    let fee: Zatoshi?
    let memo: String?
    let failed: Bool

    init?(tx: ZcashTransaction.Overview, memo: Memo?, recipient: TransactionRecipient?) {
        id = tx.id.description
        raw = tx.raw
        transactionHash = tx.rawID.hs.reversedHex
        transactionIndex = tx.index ?? 0
        toAddress = recipient?.asString
        isSentTransaction = tx.value < Zatoshi(0)
        minedHeight = tx.minedHeight
        expiryHeight = tx.expiryHeight
        timestamp = tx.blockTime ?? 0
        value = tx.value
        fee = tx.fee
        self.memo = memo.flatMap { $0.toString() }
        failed = false
    }

    init?(tx: ZcashTransaction.Sent, memo: Memo?, recipient: TransactionRecipient?) {
        id = tx.id.description
        raw = tx.raw
        transactionHash = tx.rawID?.hs.reversedHex ?? "n/a".localized
        transactionIndex = tx.index ?? 0
        toAddress = recipient?.asString
        isSentTransaction = tx.value < Zatoshi(0)
        minedHeight = tx.minedHeight
        expiryHeight = tx.expiryHeight
        timestamp = tx.blockTime ?? 0
        value = tx.value
        fee = nil // ?? todo : how to?
        self.memo = memo.flatMap { $0.toString() }
        failed = false
    }

    init?(tx: ZcashTransaction.Received, memo: Memo?, recipient: TransactionRecipient?) {
        id = tx.id.description
        raw = tx.raw
        transactionHash = tx.rawID?.hs.reversedHex ?? "n/a".localized
        transactionIndex = tx.index
        toAddress = recipient?.asString
        isSentTransaction = tx.value < Zatoshi(0)
        minedHeight = tx.minedHeight
        expiryHeight = tx.expiryHeight
        timestamp = tx.blockTime
        value = tx.value
        fee = nil // ?? todo: how to?
        self.memo = memo.flatMap { $0.toString() }
        failed = false
    }

    init?(tx: PendingTransactionEntity) {
        guard let rawTransactionId = tx.rawTransactionId else {
            return nil
        }

        id = tx.id?.description
        raw = tx.raw
        transactionHash = rawTransactionId.hs.reversedHex
        transactionIndex = -1
        toAddress = tx.recipient.asString

        // if has toAddress - we must mark tx as sent
        isSentTransaction = toAddress == nil ? tx.value < Zatoshi(0) : true
        minedHeight = nil
        expiryHeight = tx.expiryHeight
        timestamp = tx.createTime
        value = tx.value
        fee = tx.fee
        memo = tx.memo.flatMap { String(bytes: $0, encoding: .utf8) }
        failed = tx.isFailure
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
