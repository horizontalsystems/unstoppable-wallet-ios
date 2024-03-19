import EvmKit
import Foundation
import MarketKit

enum SendDataNew {
    case evm(blockchainType: BlockchainType, transactionData: TransactionData)
    case bitcoin(amount: Decimal, recipient: String)
}
