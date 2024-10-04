import Foundation
import MarketKit
import TonKit
import TonSwift

class TonTransactionRecord: TransactionRecord {
    let lt: Int64
    let inProgress: Bool
    let fee: AppValue?
    let actions: [Action]

    init(source: TransactionSource, event: Event, baseToken: Token, actions: [Action]) {
        lt = event.lt
        inProgress = event.inProgress
        fee = AppValue(token: baseToken, value: TonAdapter.amount(kitAmount: abs(event.extra)))
        self.actions = actions

        super.init(
            source: source,
            uid: event.id,
            transactionHash: event.id,
            transactionIndex: 0,
            blockHeight: nil,
            confirmationsThreshold: nil,
            date: Date(timeIntervalSince1970: TimeInterval(event.timestamp)),
            failed: false,
            spam: event.isScam
        )
    }

    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        inProgress ? .pending : .completed
    }

    override var mainValue: AppValue? {
        if actions.count == 1, let action = actions.first {
            switch action.type {
            case let .send(value, _, _, _): return value
            case let .receive(value, _, _): return value
            case let .burn(value): return value
            case let .mint(value): return value
            case let .contractCall(_, value, _): return value
            default: return nil
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
            case send(value: AppValue, to: String, sentToSelf: Bool, comment: String?)
            case receive(value: AppValue, from: String, comment: String?)
            case burn(value: AppValue)
            case mint(value: AppValue)
            case swap(routerName: String?, routerAddress: String, valueIn: AppValue, valueOut: AppValue)
            case contractDeploy(interfaces: [String])
            case contractCall(address: String, value: AppValue, operation: String)
            case unsupported(type: String)
        }
    }
}
