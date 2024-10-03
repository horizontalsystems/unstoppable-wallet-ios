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

    override var rateTokens: [Token?] {
        super.rateTokens + [fee?.token] + actions.compactMap { action in
            switch action.type {
            case let .send(value, _, _, _): return value.token
            case let .receive(value, _, _): return value.token
            default: return nil
            }
        }
    }

    override var feeInfo: (AppValue, Bool)? {
        guard let fee else {
            return nil
        }

        return (fee, false)
    }

    override func internalSections(status: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates: [Coin: CurrencyValue], nftMetadata _: [NftUid: NftAssetBriefMetadata], hidden: Bool) -> [Section] {
        var sections = [Section]()

        for action in actions {
            var fields: [TransactionField]

            switch action.type {
            case let .send(value, to, sentToSelf, comment):
                fields = sendFields(appValue: value, to: to, rates: rates, sentToSelf: sentToSelf, hidden: hidden)

                if let comment {
                    fields.append(.memo(text: comment))
                }

                if sentToSelf {
                    fields.append(sentToSelfField())
                }

            case let .receive(value, from, comment):
                fields = receiveFields(appValue: value, from: from, rates: rates, hidden: hidden)

                if let comment {
                    fields.append(.memo(text: comment))
                }

            case let .burn(value):
                fields = sendFields(appValue: value, to: nil, burn: true, rates: rates, hidden: hidden)

            case let .mint(value):
                fields = receiveFields(appValue: value, from: nil, mint: true, rates: rates, hidden: hidden)

            case let .swap(routerName, routerAddress, valueIn, valueOut):
                fields = [
                    .amount(title: youPayString(status: status), appValue: valueIn, rateValue: valueIn.coin.flatMap { rates[$0] }, type: type(appValue: valueIn, .outgoing), hidden: hidden),
                    .amount(title: youGetString(status: status), appValue: valueOut, rateValue: valueOut.coin.flatMap { rates[$0] }, type: type(appValue: valueOut, .incoming), hidden: hidden),
                    .levelValue(title: "tx_info.service".localized, value: routerName ?? routerAddress.shortened, level: .regular),
                ]

                if let tokenIn = valueIn.token, let tokenOut = valueOut.token {
                    fields.append(.price(title: "tx_info.price".localized, tokenA: tokenIn, tokenB: tokenOut, amountA: valueIn.value, amountB: valueOut.value))
                }

            case let .contractDeploy(interfaces):
                fields = [
                    .action(icon: nil, dimmed: false, title: "transactions.contract_deploy".localized, value: interfaces.joined(separator: ", ")),
                ]

            case let .contractCall(address, value, operation):
                fields = [
                    .action(icon: source.blockchainType.iconPlain32, dimmed: false, title: "transactions.contract_call".localized, value: operation),
                    .address(title: "tx_info.to_hash".localized, value: address, blockchainType: source.blockchainType),
                ]

                fields.append(contentsOf: sendFields(appValue: value, to: nil, rates: rates, hidden: hidden))

            case let .unsupported(type):
                fields = [
                    .levelValue(title: "Action", value: type, level: .regular),
                ]
            }

            switch action.status {
            case .failed:
                fields.append(.status(status: action.status))
            default: ()
            }

            sections.append(.init(fields: fields))
        }

        return sections
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
