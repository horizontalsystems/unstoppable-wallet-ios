import Foundation
import MarketKit
import TonKit

class TonOutgoingTransactionRecord: TonTransactionRecord {
    let transfers: [Transfer]
    let totalValue: TransactionValue
    let sentToSelf: Bool

    init(source: TransactionSource, event: AccountEvent, feeToken: Token, token: Token, sentToSelf: Bool) {
        var totalAmount: Decimal = 0

        transfers = event.actions.compactMap { transfer in
            guard let transfer = transfer as? TonTransfer else {
                return nil
            }
            let tonValue = TonAdapter.amount(kitAmount: Decimal(transfer.amount))
            var value: Decimal = 0
            if !tonValue.isZero {
                value = Decimal(sign: .minus, exponent: tonValue.exponent, significand: tonValue.significand)
                totalAmount += value
            }

            return Transfer(
                address: transfer.recipient.address.toString(bounceable: TonAdapter.bounceableDefault),
                value: .coinValue(token: token, value: value)
            )
        }

        totalValue = .coinValue(token: token, value: totalAmount)
        self.sentToSelf = sentToSelf

        super.init(source: source, event: event, feeToken: feeToken)
    }

    override var mainValue: TransactionValue? {
        totalValue
    }
}
