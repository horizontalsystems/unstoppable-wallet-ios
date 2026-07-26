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
    public let token: Token
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

public extension SwapApproval {
    // eip20 router-approve intent for the exact swap input; nil for a native tokenIn (no approve needed).
    static func build(spender: EvmKit.Address, tokenIn: Token, amountIn: Decimal) -> SwapApproval? {
        guard case let .eip20(tokenAddress) = tokenIn.type else {
            return nil
        }
        guard let token = try? EvmKit.Address(hex: tokenAddress) else {
            return nil
        }
        guard let amount = tokenIn.rawAmount(amountIn) else {
            return nil
        }

        return SwapApproval(spender: spender, token: token, amount: amount)
    }
}

public struct TronExecutable: ISwapExecutable {
    public let created: CreatedTransactionResponse?
    public let transferIntent: TronTransferIntent?
    public let token: Token
}

// plain p2p transfer description for routes that are a single token transfer;
// how it is broadcast is the consuming broadcaster's decision
public struct TronTransferIntent {
    public let token: TronKit.Address
    public let receiver: TronKit.Address
    public let value: BigUInt

    public init(token: TronKit.Address, receiver: TronKit.Address, value: BigUInt) {
        self.token = token
        self.receiver = receiver
        self.value = value
    }
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

// Stellar is the one chain with more than one execution shape, so the variants are cases of a
// single executable rather than sibling ISwapExecutable structs: StellarSwapBroadcaster does one
// cast and an exhaustive switch, which makes a new variant a compile error at every site that
// has to handle it. Mirrors StellarSwapMultiSwapProvider.Execution, the wire-side enum this is
// built from. Do NOT split this back into per-variant structs — brokerSession is dormant behind
// StellarSwapMultiSwapProvider.stellarBrokerEnabled and the compiler is what keeps it honest.
public struct StellarExecutable: ISwapExecutable {
    // Internal, like the payloads it carries — only the token is part of the public surface.
    enum Kind {
        // Server-built XDR (Soroswap / Aquarius / Stellar DEX): sign it and submit.
        case signed(StellarSendHelper.TransactionData)
        // StellarBroker interactive trade — the broadcaster runs the WebSocket session (the
        // broker builds + submits the txs; we sign each one) rather than broadcasting a tx.
        case brokerSession(StellarBrokerSessionClient.Params)
    }

    public let token: Token
    let kind: Kind
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
