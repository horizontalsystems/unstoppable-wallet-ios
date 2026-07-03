import BigInt
import BitcoinCore
import EvmKit
import Foundation
import MarketKit
import MoneroKit
import TronKit
import ZcashLightClientKit

// returned by the SwapFinalQuote base class; no broadcaster accepts it
struct UnsupportedExecutable: ISwapExecutable {}

public struct EvmExecutable: ISwapExecutable {
    public let transactionData: TransactionData?
    public let gasPrice: GasPrice?
    public let gasLimit: Int?
    public let nonce: Int?
    public let mevProtectionAllowed: Bool
    public let approval: SwapApproval?
}

// router-approve intent, exact amount; how it turns into on-chain approve call(s)
// is the consuming broadcaster's decision, not encoded here
public struct SwapApproval {
    public let spender: EvmKit.Address
    public let token: EvmKit.Address
    public let amount: BigUInt
}

public struct TronExecutable: ISwapExecutable {
    public let created: CreatedTransactionResponse
    public let transferIntent: TronTransferIntent?
}

// plain p2p transfer description for routes that are a single token transfer;
// how it is broadcast is the consuming broadcaster's decision
public struct TronTransferIntent {
    public let token: TronKit.Address
    public let receiver: TronKit.Address
    public let value: BigUInt
}

public struct UtxoExecutable: ISwapExecutable {
    public let token: Token
    public let sendParameters: SendParameters?
}

public struct ZcashExecutable: ISwapExecutable {
    public let token: Token
    public let proposal: Proposal?
}

public struct TonExecutable: ISwapExecutable {
    public let transactionParam: SendTransactionParam
}

public struct StellarExecutable: ISwapExecutable {
    public let token: Token
    let transactionData: StellarSendHelper.TransactionData
}

public struct MoneroExecutable: ISwapExecutable {
    public let token: Token
    public let address: String
    public let amount: MoneroSendAmount
    public let priority: SendPriority
    public let memo: String?
}

public struct ZanoExecutable: ISwapExecutable {
    public let token: Token
    public let address: String
    public let amount: ZanoSendAmount
    public let memo: String?
}

public struct SolanaExecutable: ISwapExecutable {
    public let token: Token
    public let rawTransaction: Data
}
