import Foundation
import MarketKit
import TonKit
import TonSwift

class TonTransactionRecord: TransactionRecord {
    let lt: Int64
    let inProgress: Bool
    let fee: TransactionValue?
    let actions: [Action]

    init(source: TransactionSource, event: Event, baseToken: Token, actions: [Action]) {
        lt = event.lt
        inProgress = event.inProgress
        fee = .coinValue(token: baseToken, value: TonAdapter.amount(kitAmount: abs(event.extra)))
        self.actions = actions

        super.init(
            source: source,
            uid: event.id,
            transactionHash: event.id,
            transactionIndex: 0,
            blockHeight: nil,
            confirmationsThreshold: nil,
            date: Date(timeIntervalSince1970: TimeInterval(event.timestamp)),
            failed: false
        )
    }

    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        inProgress ? .pending : .completed
    }

    override var mainValue: TransactionValue? {
        if actions.count == 1, let action = actions.first {
            switch action.type {
            case let .send(value, _, _, _): return value
            case let .receive(value, _, _): return value
            case .unsupported: return nil
            }
        }

        return nil
    }
}

extension TonTransactionRecord {
    struct Action {
        let type: `Type`
        let status: TransactionStatus

        enum `Type` {
            case send(value: TransactionValue, to: String, sentToSelf: Bool, comment: String?)
            case receive(value: TransactionValue, from: String, comment: String?)
            case unsupported(type: String)
        }
    }
}
