import Foundation
import MarketKit

/// A NEAR transaction from the account's point of view (Android `NearTransactionRecord`). Kit-free:
/// the converter projects the kit's transaction into it.
class NearTransactionRecord: TransactionRecord, TransferEventsProvider {
    let type: `Type`
    /// Gas the account paid; nil when someone else signed the transaction.
    let fee: AppValue?
    let pending: Bool
    /// Failed because it was never included before its block hash expired: nothing happened on chain.
    let expired: Bool

    init(source: TransactionSource, hash: String, blockHeight: Int?, timestamp: Int, pending: Bool, failed: Bool, expired: Bool, type: Type, fee: AppValue?, spam: Bool = false) {
        self.type = type
        self.fee = fee
        self.pending = pending
        self.expired = expired

        super.init(
            source: source,
            uid: hash,
            transactionHash: hash,
            transactionIndex: 0,
            blockHeight: blockHeight,
            // a final NEAR block cannot be reverted: no confirmation counting
            confirmationsThreshold: nil,
            date: Date(timeIntervalSince1970: TimeInterval(timestamp)),
            failed: failed,
            paginationRaw: hash,
            spam: spam
        )
    }

    // pending until its receipts have executed, then completed or failed for good
    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        if failed {
            return .failed
        }
        return pending ? .pending : .completed
    }

    override var mainValue: AppValue? {
        switch type {
        case let .send(value, _, _, _): return value
        case let .receive(value, _, _): return value
        case let .contractCall(_, _, value): return value
        }
    }

    var transferEvents: TransferEvents {
        .init(incoming: Self.eventsForPhishingCheck(type: type))
    }
}

extension NearTransactionRecord {
    enum `Type` {
        case send(value: AppValue, to: String, sentToSelf: Bool, memo: String?)
        case receive(value: AppValue, from: String, memo: String?)
        /// Any other transaction the account signed, or one that touched it without moving value to
        /// it; `value` is the NEAR it moved, if any.
        case contractCall(contractId: String, method: String?, value: AppValue?)
    }

    /// Incoming transfers only, the shape the phishing (address poisoning) check compares against.
    static func eventsForPhishingCheck(type: Type) -> [TransferEvent] {
        switch type {
        case let .receive(value, from, _): return [.init(address: from, value: value)]
        default: return []
        }
    }
}
