import EvmKit
import Foundation
import MarketKit

class UnknownSwapTransactionRecord: EvmTransactionRecord {
    let exchangeAddress: String
    let valueIn: AppValue?
    let valueOut: AppValue?

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, exchangeAddress: String, valueIn: AppValue?, valueOut: AppValue?) {
        self.exchangeAddress = exchangeAddress
        self.valueIn = valueIn
        self.valueOut = valueOut

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    override var rateTokens: [Token?] {
        super.rateTokens + [valueIn?.token, valueOut?.token]
    }

    override func internalSections(status: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates: [Coin: CurrencyValue], nftMetadata _: [NftUid: NftAssetBriefMetadata], hidden: Bool) -> [Section] {
        swapSections(exchangeAddress: exchangeAddress, valueIn: valueIn, valueOut: valueOut, status: status, rates: rates, hidden: hidden)
    }
}
