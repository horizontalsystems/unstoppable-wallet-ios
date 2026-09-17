import Foundation
import MarketKit
import XrpKit

class XrpTransactionRecord: TransactionRecord, TransferEventsProvider {
    let transaction: XrpKit.Transaction
    let fee: AppValue?
    let type: `Type`

    init(source: TransactionSource, transaction: XrpKit.Transaction, baseToken: Token, type: Type, spam: Bool) {
        self.transaction = transaction
        self.type = type
        fee = AppValue(token: baseToken, value: Amount.xrp(drops: transaction.feeDrops).decimalValue)

        super.init(
            source: source,
            uid: transaction.hash,
            transactionHash: transaction.hash,
            transactionIndex: 0,
            // a validated ledger is final: no confirmation counting
            blockHeight: transaction.ledgerIndex.map { Int($0) },
            confirmationsThreshold: nil,
            date: Date(timeIntervalSince1970: TimeInterval(transaction.timestamp)),
            failed: transaction.failed,
            paginationRaw: transaction.hash,
            spam: spam
        )
    }

    var memo: String? {
        transaction.memo
    }

    var destinationTag: UInt32? {
        transaction.destinationTag
    }

    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        if transaction.failed {
            return .failed
        }
        return transaction.validated ? .completed : .pending
    }

    override var mainValue: AppValue? {
        switch type {
        case let .send(value, _, _): return value
        case let .receive(value, _): return value
        case let .trustSet(value, _): return value
        case .unsupported: return nil
        }
    }

    var transferEvents: TransferEvents {
        .init(incoming: Self.eventsForPhishingCheck(type: type))
    }
}

extension XrpTransactionRecord {
    enum `Type` {
        case send(value: AppValue, to: String, sentToSelf: Bool)
        case receive(value: AppValue, from: String)
        case trustSet(value: AppValue, issuer: String)
        case unsupported(type: String)
    }

    /// Incoming transfers only, the shape the phishing (address poisoning) check compares against.
    static func eventsForPhishingCheck(type: Type) -> [TransferEvent] {
        switch type {
        case let .receive(value, from): return [.init(address: from, value: value)]
        default: return []
        }
    }
}
