import EvmKit
import MarketKit
import WalletCore

class ContractCreationTransactionRecord: EvmTransactionRecord {
    init(source: WalletCore.TransactionSource, transaction: Transaction, baseToken: Token, protected: Bool) {
        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true, protected: protected)
    }
}
