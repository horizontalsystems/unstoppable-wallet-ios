import BigInt
import BitcoinCore
import EvmKit
import Foundation
import MarketKit
import SolanaKit
import StellarKit
import TonSwift
import TronKit
import ZcashLightClientKit

public enum SendData {
    case evm(blockchainType: BlockchainType, transactionData: TransactionData, token: Token)
    case bitcoin(token: Token, params: SendParameters)
    case zcash(amount: Decimal, recipient: Recipient, memo: String?)
    case zcashResend(amount: Decimal, recipient: Recipient, memo: String?, initialTransactionSettings: InitialTransactionSettings)
    case zcashShield(amount: Decimal, recipient: Recipient?, memo: String?)
    case tron(token: Token, contract: TronKit.Contract)
    case tronGasFree(token: Token, receiver: TronKit.Address, value: BigUInt)
    case ton(token: Token, amount: Decimal, address: FriendlyAddress, memo: String?)
    case stellar(data: StellarSendData, token: Token, memo: String?)
    case solana(token: Token, amount: Decimal, address: String, memo: String?)
    case swap(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider, multiSwapQuote: MultiSwapQuote)
    case walletConnect(request: WalletConnectRequest)
    case tonConnect(request: TonConnectSendTransactionRequest)
    case monero(token: Token, amount: MoneroSendAmount, address: String, memo: String?)
    case zano(token: Token, amount: ZanoSendAmount, address: String, memo: String?)
    case zanoAsset(token: Token, baseToken: Token, amount: ZanoSendAmount, address: String, memo: String?)
    indirect case openCryptoPay(payment: OpenCryptoPayPayment, entry: OpenCryptoPayPayment.Entry, inner: SendData)
}

public enum StellarSendData {
    case payment(asset: Asset, amount: Decimal, accountId: String)
    case changeTrust(asset: Asset, limit: Decimal)
}
