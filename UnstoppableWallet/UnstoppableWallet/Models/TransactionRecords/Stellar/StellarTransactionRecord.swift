import Foundation
import MarketKit
import StellarKit

class StellarTransactionRecord: TransactionRecord {
    let operation: TxOperation
    let fee: AppValue?
    let type: `Type`

    init(source: TransactionSource, operation: TxOperation, baseToken: Token, type: Type, spam: Bool) {
        self.operation = operation
        fee = operation.feeCharged.map { AppValue(token: baseToken, value: $0) }
        self.type = type

        super.init(
            source: source,
            uid: operation.id,
            transactionHash: operation.transactionHash,
            transactionIndex: 0,
            blockHeight: nil,
            confirmationsThreshold: nil,
            date: operation.createdAt,
            failed: !operation.transactionSuccessful,
            paginationRaw: operation.pagingToken,
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
}

extension StellarTransactionRecord {
    enum `Type` {
        case accountCreated(startingBalance: AppValue, funder: String)
        case accountFunded(startingBalance: AppValue, account: String)
        case sendPayment(value: AppValue, to: String, sentToSelf: Bool)
        case receivePayment(value: AppValue, from: String)
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
