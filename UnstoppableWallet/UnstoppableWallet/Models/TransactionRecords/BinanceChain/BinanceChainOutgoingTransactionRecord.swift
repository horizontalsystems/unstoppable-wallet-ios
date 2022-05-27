import Foundation
import BinanceChainKit
import MarketKit

class BinanceChainOutgoingTransactionRecord: BinanceChainTransactionRecord {
    let value: TransactionValue
    let to: String
    let sentToSelf: Bool

    init(source: TransactionSource, transaction: TransactionInfo, feeCoin: PlatformCoin, coin: PlatformCoin, sentToSelf: Bool) {
        value = .coinValue(platformCoin: coin, value: Decimal(sign: .minus, exponent: transaction.amount.exponent, significand: transaction.amount.significand))
        to = transaction.to
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, feeCoin: feeCoin)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
