import Foundation
import ZcashLightClientKit
import HsExtensions

class ZcashTransaction {
    let id: String?
    let raw: Data?
    let transactionHash: String
    let transactionIndex: Int
    let toAddress: String?
    let expiryHeight: Int?
    let minedHeight: Int?
    let timestamp: TimeInterval
    let value: Zatoshi
    let memo: String?
    let failed: Bool

    init?(confirmedTransaction: ConfirmedTransactionEntity) {
        guard let rawTransactionId = confirmedTransaction.rawTransactionId else {
            return nil
        }

        id = confirmedTransaction.id?.description
        raw = confirmedTransaction.raw
        transactionHash = rawTransactionId.hs.reversedHex
        transactionIndex = confirmedTransaction.transactionIndex
        toAddress = confirmedTransaction.toAddress
        minedHeight = confirmedTransaction.minedHeight
        expiryHeight = confirmedTransaction.expiryHeight
        timestamp = confirmedTransaction.blockTimeInSeconds
        value = confirmedTransaction.value
        memo = confirmedTransaction.memo.flatMap { String(bytes: $0, encoding: .utf8) }
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
        toAddress = pendingTransaction.toAddress
        minedHeight = nil
        expiryHeight = pendingTransaction.expiryHeight
        timestamp = pendingTransaction.createTime
        value = pendingTransaction.value
        memo = pendingTransaction.memo.flatMap { String(bytes: $0, encoding: .utf8) }
        failed = pendingTransaction.isFailure
    }

    func sentTo(address: String) -> Bool {
        if let toAddress = toAddress, toAddress != address {
            return false
        }

        return true
    }

}

extension ZcashTransaction: Comparable {

    public static func <(lhs: ZcashTransaction, rhs: ZcashTransaction) -> Bool {
        if lhs.timestamp != rhs.timestamp {
            return lhs.timestamp > rhs.timestamp
        } else {
            return lhs.transactionIndex > rhs.transactionIndex
        }
    }

    public static func ==(lhs: ZcashTransaction, rhs: ZcashTransaction) -> Bool {
        lhs.transactionHash == rhs.transactionHash
    }

}

extension ZcashTransaction: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(transactionHash)
    }

}

extension ZcashTransaction {

    var description: String {
        "TX(Zcash) === hash:\(transactionHash) : \(toAddress?.prefix(6) ?? "N/A") : \(transactionIndex) height: \(minedHeight?.description ?? "N/A") timestamp \(timestamp.description)"
    }

}
