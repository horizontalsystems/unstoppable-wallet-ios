import EvmKit
import MarketKit

class ContractCreationTransactionRecord: EvmTransactionRecord {

    init(source: TransactionSource, transaction: Transaction, baseToken: Token) {
        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

}
