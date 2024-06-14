import BitcoinCore
import EvmKit
import Foundation
import MarketKit
import TronKit
import ZcashLightClientKit

enum SendData {
    case evm(blockchainType: BlockchainType, transactionData: TransactionData)
    case bitcoin(token: Token, params: SendParameters)
    case binance(token: Token, amount: Decimal, address: String, memo: String?)
    case zcash(amount: Decimal, recipient: Recipient, memo: String?)
    case tron(token: Token, contract: Contract)
    case swap(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider)
    case walletConnect(request: WalletConnectRequest)
}
