import BinanceChainKit
import Foundation
import MarketKit

class BinanceChainOutgoingTransactionRecord: BinanceChainTransactionRecord {
    let value: AppValue
    let to: String
    let sentToSelf: Bool

    init(source: TransactionSource, transaction: TransactionInfo, feeToken: Token, token: Token, sentToSelf: Bool) {
        value = AppValue(token: token, value: Decimal(sign: .minus, exponent: transaction.amount.exponent, significand: transaction.amount.significand))
        to = transaction.to
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: AppValue? {
        value
    }

    override var rateTokens: [Token?] {
        super.rateTokens + [value.token]
    }

    override var feeInfo: (AppValue, Bool)? {
        (fee, false)
    }

    override func internalSections(status _: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates: [Coin: CurrencyValue], nftMetadata _: [NftUid: NftAssetBriefMetadata], hidden: Bool) -> [Section] {
        var sections: [Section] = [
            .init(
                fields: sendFields(appValue: value, to: to, rates: rates, sentToSelf: sentToSelf, hidden: hidden)
            ),
        ]

        if let memo, !memo.isEmpty {
            sections.append(.init(fields: [.memo(text: memo)]))
        }

        if sentToSelf {
            sections.append(.init(fields: [sentToSelfField()]))
        }

        return sections
    }
}
