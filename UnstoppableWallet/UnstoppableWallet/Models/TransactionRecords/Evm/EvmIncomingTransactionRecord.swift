import EvmKit
import Foundation
import MarketKit

class EvmIncomingTransactionRecord: EvmTransactionRecord {
    let from: String
    let value: AppValue

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, from: String, value: AppValue) {
        self.from = from
        self.value = value

        let spam: Bool

        switch value.kind {
        case .token:
            spam = value.value == 0
        default:
            spam = false
        }

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false, spam: spam)
    }

    override var mainValue: AppValue? {
        value
    }

    override var rateTokens: [Token?] {
        super.rateTokens + [value.token]
    }

    override func internalSections(status _: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates: [Coin: CurrencyValue], nftMetadata _: [NftUid: NftAssetBriefMetadata], hidden: Bool) -> [Section] {
        [
            .init(
                fields: receiveFields(appValue: value, from: from, mint: from == zeroAddress, rates: rates, hidden: hidden)
            ),
        ]
    }
}
