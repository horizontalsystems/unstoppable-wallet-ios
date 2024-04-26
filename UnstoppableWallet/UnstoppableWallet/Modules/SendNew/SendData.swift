import EvmKit
import Foundation
import MarketKit

enum SendData {
    case evm(blockchainType: BlockchainType, transactionData: TransactionData)
    case bitcoin(amount: Decimal, recipient: String)
    case swap(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider)
}
