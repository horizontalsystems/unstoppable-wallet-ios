import Foundation
import MarketKit

class BitcoinIncomingTransactionRecord: BitcoinTransactionRecord {
    let value: AppValue
    let from: String?

    init(token: Token, source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool,
         lockInfo: TransactionLockInfo?, conflictingHash: String?, showRawTransaction: Bool,
         amount: Decimal, from: String?, memo: String? = nil)
    {
        value = AppValue(token: token, value: amount)
        self.from = from

        super.init(
            source: source,
            uid: uid,
            transactionHash: transactionHash,
            transactionIndex: transactionIndex,
            blockHeight: blockHeight,
            confirmationsThreshold: confirmationsThreshold,
            date: date,
            fee: fee.flatMap { AppValue(token: token, value: $0) },
            failed: failed,
            lockInfo: lockInfo,
            conflictingHash: conflictingHash,
            showRawTransaction: showRawTransaction,
            memo: memo
        )
    }

    override var mainValue: AppValue? {
        value
    }

    override var rateTokens: [Token?] {
        super.rateTokens + [value.token]
    }

    override func internalSections(status _: TransactionStatus, lastBlockInfo: LastBlockInfo?, rates: [Coin: CurrencyValue], nftMetadata _: [NftUid: NftAssetBriefMetadata], hidden: Bool) -> [Section] {
        var sections: [Section] = [
            .init(fields: receiveFields(appValue: value, from: from, rates: rates, hidden: hidden)),
        ]

        let additionalFields = fields(lastBlockInfo: lastBlockInfo)

        if !additionalFields.isEmpty {
            sections.append(.init(fields: additionalFields))
        }

        return sections
    }
}
