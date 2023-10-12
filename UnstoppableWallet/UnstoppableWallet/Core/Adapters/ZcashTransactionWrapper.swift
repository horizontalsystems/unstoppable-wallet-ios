import Foundation
import ZcashLightClientKit
import HsExtensions

class ZcashTransactionWrapper {
    let raw: Data?
    let transactionHash: String
    let transactionIndex: Int
    let recipientAddress: String?
    let isSentTransaction: Bool
    let expiryHeight: Int?
    let minedHeight: Int?
    let timestamp: TimeInterval
    let value: Zatoshi
    let fee: Zatoshi?
    let memo: String?
    let failed: Bool

    init?(tx: ZcashTransaction.Overview, memo: String?, recipient: TransactionRecipient?, lastBlockHeight: Int) {
        raw = tx.raw
        transactionHash = tx.rawID.hs.reversedHex
        transactionIndex = tx.index ?? 0
        var toAddress: String?
        if case let .address(recipient) = recipient {
            toAddress = recipient.stringEncoded
        }
        recipientAddress = toAddress
        isSentTransaction = tx.isSentTransaction
        minedHeight = tx.minedHeight
        expiryHeight = tx.expiryHeight
        failed = tx.getState(for: lastBlockHeight) == .expired
        timestamp = failed ? 0 : (tx.blockTime ?? Date().timeIntervalSince1970) // need this to update pending transactions and shows on transaction tab
        value = tx.value
        fee = tx.fee
        self.memo = memo
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
        "TX(Zcash) === hash:\(transactionHash) : \(recipientAddress?.prefix(6) ?? "N/A") : \(transactionIndex) height: \(minedHeight?.description ?? "N/A") timestamp \(timestamp.description)"
    }

}
