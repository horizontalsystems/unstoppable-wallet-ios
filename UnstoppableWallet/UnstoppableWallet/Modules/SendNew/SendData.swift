import BitcoinCore
import EvmKit
import Foundation
import MarketKit
import TonSwift
import TronKit
import ZcashLightClientKit

enum SendData {
    case evm(blockchainType: BlockchainType, transactionData: TransactionData)
    case bitcoin(token: Token, params: SendParameters)
    case zcash(amount: Decimal, recipient: Recipient, memo: String?)
    case tron(token: Token, contract: TronKit.Contract)
    case ton(token: Token, amount: Decimal, address: FriendlyAddress, memo: String?)
    case stellar(token: Token, amount: Decimal, accountId: String, memo: String?)
    case swap(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider)
    case walletConnect(request: WalletConnectRequest)
    case tonConnect(request: TonConnectSendTransactionRequest)
}
