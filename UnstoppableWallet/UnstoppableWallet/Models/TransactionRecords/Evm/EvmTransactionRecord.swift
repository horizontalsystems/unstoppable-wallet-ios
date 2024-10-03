import EvmKit
import Foundation
import MarketKit

class EvmTransactionRecord: TransactionRecord {
    let zeroAddress = "0x0000000000000000000000000000000000000000"

    let transaction: Transaction
    let ownTransaction: Bool
    let fee: AppValue?

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, ownTransaction: Bool, spam: Bool = false) {
        self.transaction = transaction
        let txHash = transaction.hash.hs.hexString
        self.ownTransaction = ownTransaction

        if let feeAmount = transaction.gasUsed ?? transaction.gasLimit, let gasPrice = transaction.gasPrice {
            let feeDecimal = Decimal(sign: .plus, exponent: -baseToken.decimals, significand: Decimal(feeAmount) * Decimal(gasPrice))
            fee = AppValue(token: baseToken, value: feeDecimal)
        } else {
            fee = nil
        }

        super.init(
            source: source,
            uid: txHash,
            transactionHash: txHash,
            transactionIndex: transaction.transactionIndex ?? 0,
            blockHeight: transaction.blockNumber,
            confirmationsThreshold: BaseEvmAdapter.confirmationsThreshold,
            date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
            failed: transaction.isFailed,
            spam: spam
        )
    }

    override var rateTokens: [Token?] {
        super.rateTokens + [fee?.token]
    }

    override var feeInfo: (AppValue, Bool)? {
        guard ownTransaction, let fee else {
            return nil
        }

        return (fee, true)
    }

    override func isResendable(status: TransactionStatus) -> Bool {
        ownTransaction && status.isPending
    }

    func combined(incomingEvents: [TransferEvent], outgoingEvents: [TransferEvent]) -> ([AppValue], [AppValue]) {
        let values = (incomingEvents + outgoingEvents).map(\.value)
        var resultIncoming = [AppValue]()
        var resultOutgoing = [AppValue]()

        for value in values {
            if (resultIncoming + resultOutgoing).contains(where: { value.kind == $0.kind }) {
                continue
            }

            let sameTypeValues = values.filter { value.kind == $0.kind }
            let totalValue = sameTypeValues.map(\.value).reduce(0, +)
            let resultValue = AppValue(kind: value.kind, value: totalValue)

            if totalValue > 0 {
                resultIncoming.append(resultValue)
            } else {
                resultOutgoing.append(resultValue)
            }
        }

        return (resultIncoming, resultOutgoing)
    }

    func swapSections(exchangeAddress: String, valueIn: AppValue?, valueOut: AppValue?, recipient: String? = nil, status: TransactionStatus, rates: [Coin: CurrencyValue], hidden: Bool) -> [Section] {
        var sections = [Section]()

        var amountFields = [TransactionField]()

        if let valueIn {
            amountFields.append(.amount(title: youPayString(status: status), appValue: valueIn, rateValue: valueIn.coin.flatMap { rates[$0] }, type: type(appValue: valueIn, .outgoing), hidden: hidden))
        }

        if let valueOut {
            amountFields.append(.amount(title: youGetString(status: status), appValue: valueOut, rateValue: valueOut.coin.flatMap { rates[$0] }, type: type(appValue: valueOut, condition: recipient == nil, .incoming, .outgoing), hidden: hidden))
        }

        sections.append(.init(fields: amountFields))

        if let recipient {
            sections.append(.init(fields: [
                .address(title: "tx_info.recipient_hash".localized, value: recipient, blockchainType: source.blockchainType),
            ]))
        }

        var fields: [TransactionField] = [
            .levelValue(title: "tx_info.service".localized, value: exchangeAddress.shortened, level: .regular),
        ]

        if let valueIn, let tokenIn = valueIn.token, let valueOut, let tokenOut = valueOut.token {
            switch status {
            case .pending, .processing, .completed:
                fields.append(.price(title: "tx_info.price".localized, tokenA: tokenIn, tokenB: tokenOut, amountA: valueIn.value, amountB: valueOut.value))
            default: ()
            }
        }

        sections.append(.init(fields: fields))

        return sections
    }
}

extension EvmTransactionRecord {
    struct TransferEvent {
        let address: String
        let value: AppValue
    }
}
