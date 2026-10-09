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
    /// The account signed it: what it brought, such as a swap's proceeds, is not an attempt to mislead.
    let signed: Bool

    init(source: TransactionSource, hash: String, blockHeight: Int?, timestamp: Int, pending: Bool, failed: Bool, expired: Bool, signed: Bool, type: Type, fee: AppValue?, spam: Bool = false) {
        self.type = type
        self.fee = fee
        self.pending = pending
        self.expired = expired
        self.signed = signed

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
        case let .contractCall(_, _, incoming, outgoing): return (incoming + outgoing).count == 1 ? (incoming + outgoing)[0].value : nil
        }
    }

    // Only the account's signature moves its NEAR or its tokens (NEP-141 has no allowance), so an
    // outgoing leg in a transaction someone else signed is a forged event log: handed to the spam
    // check as outgoing, as an EVM external contract call is (iOS only: Android checks incoming only)
    var transferEvents: TransferEvents {
        guard !signed else {
            return .init()
        }
        return .init(incoming: Self.eventsForPhishingCheck(type: type), outgoing: Self.outgoingEvents(type: type))
    }
}

extension NearTransactionRecord {
    enum `Type` {
        case send(value: AppValue, to: String, sentToSelf: Bool, memo: String?)
        case receive(value: AppValue, from: String, memo: String?)
        /// Any other transaction, with the account's net movement per asset: none for a call that
        /// moved nothing, several for a swap or a wrap (Android `Type.ContractCall`).
        case contractCall(contractId: String, method: String?, incoming: [TransferEvent], outgoing: [TransferEvent])
    }

    /// Incoming transfers only, the shape the phishing (address poisoning) check compares against.
    static func eventsForPhishingCheck(type: Type) -> [TransferEvent] {
        switch type {
        case let .receive(value, from, _): return [.init(address: from, value: value)]
        case let .contractCall(_, _, incoming, _): return incoming
        case .send: return []
        }
    }

    static func outgoingEvents(type: Type) -> [TransferEvent] {
        switch type {
        case let .send(value, to, _, _): return [.init(address: to, value: value)]
        case let .contractCall(_, _, _, outgoing): return outgoing
        case .receive: return []
        }
    }
}
