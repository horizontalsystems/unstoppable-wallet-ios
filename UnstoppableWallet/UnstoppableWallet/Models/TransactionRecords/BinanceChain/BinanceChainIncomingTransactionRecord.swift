import BinanceChainKit
import MarketKit

class BinanceChainIncomingTransactionRecord: BinanceChainTransactionRecord {
    let value: AppValue
    let from: String

    init(source: TransactionSource, transaction: TransactionInfo, feeToken: Token, token: Token) {
        value = AppValue(token: token, value: transaction.amount)
        from = transaction.from

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: AppValue? {
        value
    }

    override var rateTokens: [Token?] {
        super.rateTokens + [value.token]
    }

    override func internalSections(status _: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates: [Coin: CurrencyValue], nftMetadata _: [NftUid: NftAssetBriefMetadata], hidden: Bool) -> [Section] {
        var sections: [Section] = [
            .init(
                fields: receiveFields(appValue: value, from: from, rates: rates, hidden: hidden)
            ),
        ]

        if let memo, !memo.isEmpty {
            sections.append(.init(fields: [.memo(text: memo)]))
        }

        return sections
    }
}
