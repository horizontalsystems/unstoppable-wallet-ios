import BigInt
import BitcoinCore
import EvmKit
import Foundation
import MarketKit
import SolanaKit
import StellarKit
import ThorChainKit
import TonSwift
import TronKit
import ZcashLightClientKit

public enum SendData {
    case evm(blockchainType: BlockchainType, transactionData: TransactionData, token: Token)
    case bitcoin(token: Token, params: SendParameters)
    case zcash(amount: Decimal, recipient: Recipient, memo: String?)
    case zcashResend(amount: Decimal, recipient: Recipient, memo: String?, initialTransactionSettings: InitialTransactionSettings)
    case zcashShield(amount: Decimal, recipient: Recipient?, memo: String?)
    case zcashMigration
    case tron(token: Token, contract: TronKit.Contract)
    case tronGasFree(token: Token, receiver: TronKit.Address, value: BigUInt)
    case ton(token: Token, amount: Decimal, address: FriendlyAddress, memo: String?)
    case stellar(data: StellarSendData, token: Token, memo: String?)
    case solana(token: Token, amount: Decimal, address: String, memo: String?)
    // recipientHolder: external delivery address entered before confirmation when the account
    // can't hold tokenOut; empty when the swap is delivered to the account's own wallet. A
    // shared box rather than a value so a recipient edited on the confirmation screen is
    // visible to the swap screen that opened it.
    case swap(tokenIn: Token, tokenOut: Token, amountIn: Decimal, provider: IMultiSwapProvider, multiSwapQuote: MultiSwapQuote, recipientHolder: SwapExternalRecipientHolder)
    case walletConnect(request: WalletConnectRequest)
    case tonConnect(request: TonConnectSendTransactionRequest)
    case monero(token: Token, amount: MoneroSendAmount, address: String, memo: String?, selectedKeyImages: [String]?)
    case zano(token: Token, amount: ZanoSendAmount, address: String, memo: String?)
    case zanoAsset(token: Token, baseToken: Token, amount: ZanoSendAmount, address: String, memo: String?)
    case thorChain(token: Token, amount: ThorChainKit.SendAmount, recipient: ThorChainKit.Address, memo: String?)
    indirect case openCryptoPay(payment: OpenCryptoPayPayment, entry: OpenCryptoPayPayment.Entry, inner: SendData)
    indirect case payment(info: PaymentInfo, inner: SendData)
    // Unlike the two decorator cases above, this one carries no inner SendData: with no pre-send
    // quoting and exact-output semantics, neither the deposit address nor the amount to transfer
    // exists yet. Both are the commit's answer, so the inner send is built inside the handler.
    case privateSend(request: PrivateSendRequest)
}

// App-agnostic display + reporting payload attached to a merchant payment send. Carried through the
// neutral send flow so a Stable-side decorator handler (registered via SendHandlerFactory) can render
// the merchant/rate/KGS fields and report the on-chain deposit to stable-backend. WalletCore itself
// stays payment-backend-agnostic (mirrors the openCryptoPay case).
public struct PaymentInfo {
    public let recipient: String
    public let rate: Decimal
    public let amount: Decimal
    public let tokenAmount: Decimal
    public let qrLink: String
    public let chain: String
    public let token: String

    public init(recipient: String, rate: Decimal, amount: Decimal, tokenAmount: Decimal, qrLink: String, chain: String, token: String) {
        self.recipient = recipient
        self.rate = rate
        self.amount = amount
        self.tokenAmount = tokenAmount
        self.qrLink = qrLink
        self.chain = chain
        self.token = token
    }
}

public enum StellarSendData {
    case payment(asset: StellarKit.Asset, amount: Decimal, accountId: String)
    case changeTrust(asset: StellarKit.Asset, limit: Decimal)
}
