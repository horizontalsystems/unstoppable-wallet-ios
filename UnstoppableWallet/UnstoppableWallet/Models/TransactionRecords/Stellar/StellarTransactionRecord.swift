import Foundation
import MarketKit
import StellarKit

class StellarTransactionRecord: TransactionRecord {
    let operation: TxOperation
    let type: `Type`

    init(source: TransactionSource, operation: TxOperation, baseToken _: Token, type: Type) {
        self.operation = operation
        self.type = type

        super.init(
            source: source,
            uid: operation.id,
            transactionHash: operation.id,
            transactionIndex: 0,
            blockHeight: nil,
            confirmationsThreshold: nil,
            date: operation.createdAt,
            failed: !operation.transactionSuccessful,
            spam: false
        )
    }

    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        operation.transactionSuccessful ? .completed : .failed
    }

    override var mainValue: AppValue? {
        switch type {
        case let .accountCreated(startingBalance, _): return startingBalance
        case let .sendPayment(value, _, _): return value
        case let .receivePayment(value, _): return value
        default: return nil
        }
    }
}

extension StellarTransactionRecord {
    enum `Type` {
        case accountCreated(startingBalance: AppValue, funder: String)
        case sendPayment(value: AppValue, to: String, sentToSelf: Bool)
        case receivePayment(value: AppValue, from: String)
        case unsupported(type: String)
    }
}
