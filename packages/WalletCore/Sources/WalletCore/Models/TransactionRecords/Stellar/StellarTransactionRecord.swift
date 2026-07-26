import Foundation
import MarketKit
import StellarKit

/// ONE record per Stellar TRANSACTION (the TON model). A tx carries several operations —
/// e.g. a STELLAR_DEX swap ships the service-fee payment op in the same atomic tx — and
/// rendering each op as its own list row split one user action into confusing siblings with
/// the same hash. The adapter groups same-tx operations; `type` is the PRIMARY action (drives
/// the list cell), `additionalActions` are the tx's other fund flows, shown only on Tx Info.
class StellarTransactionRecord: TransactionRecord, TransferEventsProvider {
    let operation: TxOperation
    let fee: AppValue?
    let type: `Type`
    let additionalActions: [Type]

    init(source: TransactionSource, operations: [TxOperation], baseToken: Token, types: [Type], primaryIndex: Int, spam: Bool) {
        let primary = operations[primaryIndex]
        operation = primary
        fee = primary.feeCharged.map { AppValue(token: baseToken, value: $0) }
        type = types[primaryIndex]
        additionalActions = types.enumerated().filter { $0.offset != primaryIndex }.map(\.element)

        super.init(
            source: source,
            uid: primary.id,
            transactionHash: primary.transactionHash,
            transactionIndex: 0,
            blockHeight: nil,
            confirmationsThreshold: nil,
            date: primary.createdAt,
            failed: !primary.transactionSuccessful,
            // The cursor must continue past the WHOLE tx: the last op in listed order is
            // correct for both descending (list) and ascending (full-scan) queries.
            paginationRaw: operations.last?.pagingToken ?? primary.pagingToken,
            spam: spam
        )
    }

    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        operation.transactionSuccessful ? .completed : .failed
    }

    override var mainValue: AppValue? {
        switch type {
        case let .accountCreated(startingBalance, _): return startingBalance
        case let .accountFunded(startingBalance, _): return startingBalance
        case let .sendPayment(value, _, _): return value
        case let .receivePayment(value, _): return value
        case let .changeTrust(value, _, _, _): return value
        default: return nil
        }
    }

    var transferEvents: TransferEvents {
        let incomingEvents = ([type] + additionalActions).flatMap { StellarTransactionRecord.doubtfulEvents(type: $0) }
        return .init(incoming: incomingEvents)
    }
}

extension StellarTransactionRecord {
    enum `Type` {
        case accountCreated(startingBalance: AppValue, funder: String)
        case accountFunded(startingBalance: AppValue, account: String)
        case sendPayment(value: AppValue, to: String, sentToSelf: Bool)
        case receivePayment(value: AppValue, from: String)
        // valueIn = what the account spent (negative), valueOut = what it received (positive) —
        // the TON swap action's naming. Covers path payments and Soroban DEX invocations.
        case swap(valueIn: AppValue, valueOut: AppValue)
        case changeTrust(value: AppValue, trustor: String, trustee: String?, liquidityPoolId: String?)
        case unsupported(type: String)
    }
}

extension StellarTransactionRecord {
    static func doubtfulEvents(type: Type) -> [TransferEvent] {
        switch type {
        case let .receivePayment(value: value, from: from): return [.init(address: from, value: value)]
        default: return []
        }
    }
}
