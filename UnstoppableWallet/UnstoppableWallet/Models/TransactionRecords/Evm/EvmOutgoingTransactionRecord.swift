import EvmKit
import Foundation
import MarketKit

class EvmOutgoingTransactionRecord: EvmTransactionRecord {
    let to: String
    let value: AppValue
    let sentToSelf: Bool

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, to: String, value: AppValue, sentToSelf: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    override var mainValue: AppValue? {
        value
    }

    override var rateTokens: [Token?] {
        super.rateTokens + [value.token]
    }

    override func internalSections(status _: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates: [Coin: CurrencyValue], nftMetadata: [NftUid: NftAssetBriefMetadata], hidden: Bool) -> [Section] {
        var sections: [Section] = [
            .init(
                fields: sendFields(appValue: value, to: to, burn: to == zeroAddress, rates: rates, nftMetadata: nftMetadata, sentToSelf: sentToSelf, hidden: hidden)
            ),
        ]

        if sentToSelf {
            sections.append(.init(fields: [sentToSelfField()]))
        }

        return sections
    }
}
