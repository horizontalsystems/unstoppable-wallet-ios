import Foundation
import MarketKit
import TonKit
import TonSwift
import BigInt

class TonIncomingTransactionRecord: TonTransactionRecord {
    let transfer: Transfer?

    init(source: TransactionSource, event: AccountEvent, feeToken: Token, token: Token) {
        transfer = event
            .actions
            .compactMap { $0 as? TonTransfer }
            .first
            .map { transfer in
                Transfer(
                    address: transfer.recipient.address.toString(bounceable: TonAdapter.bounceableDefault),
                    value: .coinValue(token: token, value: TonAdapter.amount(kitAmount: Decimal(transfer.amount)))
                )
        }

        super.init(source: source, event: event, feeToken: feeToken)
    }

    override var mainValue: TransactionValue? {
        transfer?.value
    }
}
