import EvmKit
import Foundation
import MarketKit

class ApproveTransactionRecord: EvmTransactionRecord {
    let spender: String
    let value: AppValue

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, spender: String, value: AppValue) {
        self.spender = spender
        self.value = value

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    override var mainValue: AppValue? {
        value
    }

    override var rateTokens: [Token?] {
        super.rateTokens + [value.token]
    }

    override func internalSections(status _: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates: [Coin: CurrencyValue], nftMetadata _: [NftUid: NftAssetBriefMetadata], hidden: Bool) -> [Section] {
        let rateValue = value.coin.flatMap { rates[$0] }

        var fields: [TransactionField] = [
            .amount(title: "transactions.approve".localized, appValue: value, rateValue: rateValue, type: .neutral, hidden: hidden),
            .address(title: "tx_info.spender".localized, value: spender, blockchainType: source.blockchainType),
        ]

        if let rateField = rate(rateValue: rateValue, code: value.code) {
            fields.append(rateField)
        }

        return [.init(fields: fields)]
    }
}
