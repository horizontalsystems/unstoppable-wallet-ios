import EthereumKit
import MarketKit

class ContractCreationTransactionRecord: EvmTransactionRecord {

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin) {
        super.init(source: source, transaction: transaction, baseCoin: baseCoin, ownTransaction: true)
    }

}
