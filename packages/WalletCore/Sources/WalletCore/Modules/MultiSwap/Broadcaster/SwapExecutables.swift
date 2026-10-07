import BigInt
import BitcoinCore
import EvmKit
import Foundation
import MarketKit
import MoneroKit
import ThorChainKit
import TonSwift
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

// Tron, Solana and TON each have two execution shapes — a server-built transaction, or a plain
// transfer the app builds itself for a USwap transfer route — so, like StellarExecutable below, the
// variants are cases of one executable: the broadcaster does one cast and an exhaustive switch.
public struct TronExecutable: ISwapExecutable {
    enum Kind {
        // Server-built transaction (signed_transaction route): sign it and submit.
        case created(CreatedTransactionResponse)
        // Plain transfer to a deposit address, built locally through the send kit.
        case transfer(TronTransferExecution)
    }

    let kind: Kind?
    public let transferIntent: TronTransferIntent?
    public let token: Token
}

// plain transfer to a deposit address: the contract to sign and the fee limit from its estimate
public struct TronTransferExecution {
    public let contract: TronKit.Contract
    public let feeLimit: Int

    public init(contract: TronKit.Contract, feeLimit: Int) {
        self.contract = contract
        self.feeLimit = feeLimit
    }
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
    enum Kind {
        // Server-built TonConnect-style transaction: build the transfer from it and sign.
        case param(SendTransactionParam)
        // Plain transfer to a deposit address, built locally through the send adapter.
        case transfer(TonTransferExecution)
    }

    public let token: Token
    let kind: Kind?
}

public struct TonTransferExecution {
    public let recipient: FriendlyAddress
    public let amount: Decimal
    public let comment: String?

    public init(recipient: FriendlyAddress, amount: Decimal, comment: String?) {
        self.recipient = recipient
        self.amount = amount
        self.comment = comment
    }
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

public struct ThorChainExecutable: ISwapExecutable {
    enum Kind {
        // No inbound vault: the swap is a MsgDeposit addressed to the chain.
        case deposit(asset: ThorChainKit.Asset)
        // Maya and anything with a vault: an ordinary transfer into it.
        case send(recipient: ThorChainKit.Address)
    }

    public let token: Token
    let kind: Kind
    let amount: Decimal
    let memo: String
}

public struct XrpExecutable: ISwapExecutable {
    public let token: Token
    public let address: String
    public let amount: Decimal
    /// The provider's crediting identifier: a field of the Payment, never a memo.
    public let destinationTag: UInt32?
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
    enum Kind {
        // Server-built transaction message: sign it and submit.
        case raw(Data)
        // Plain SOL / SPL transfer to a deposit address (no memo can ride it).
        case transfer(SolanaTransferExecution)
    }

    public let token: Token
    let kind: Kind?
}

public struct SolanaTransferExecution {
    public let toAddress: String
    public let amount: Decimal

    public init(toAddress: String, amount: Decimal) {
        self.toAddress = toAddress
        self.amount = amount
    }
}
