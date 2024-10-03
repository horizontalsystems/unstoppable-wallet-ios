import EvmKit
import MarketKit

class ContractCreationTransactionRecord: EvmTransactionRecord {
    init(source: TransactionSource, transaction: Transaction, baseToken: Token) {
        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    override func internalSections(status _: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates _: [Coin: CurrencyValue], nftMetadata _: [NftUid: NftAssetBriefMetadata], hidden _: Bool) -> [Section] {
        [.init(fields: [
            .action(icon: source.blockchainType.iconPlain32, dimmed: false, title: "transactions.contract_creation".localized, value: nil),
        ])]
    }
}
