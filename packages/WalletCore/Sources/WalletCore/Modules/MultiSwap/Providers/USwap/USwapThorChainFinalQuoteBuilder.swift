import Foundation
import MarketKit
import ThorChainKit

// RUNE / CACAO / THORChain-token / secured-asset sells on a thorchain_deposit route. A
// settlement-native sell (the server names no vault, `delivery.kind == "cosmos_memo"`) is a
// MsgDeposit of the sell amount carrying the memo; only when the server names an inbound vault
// is it a bank send to that vault, carrying the memo.
final class USwapThorChainFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private static let cosmosMemoDeliveryKind = "cosmos_memo"

    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .thorChain || input.tokenIn.blockchainType == .mayaChain
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        // Only a thorchain_deposit route is executable on these chains; the memo was validated by
        // USwapMultiSwapProvider before the builder runs.
        guard case let .thorchainDeposit(_, inboundAddress, memo, delivery) = input.response.execution else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

        // A cosmos_memo route is a MsgDeposit on the chain itself and names no vault. A vault
        // address alongside it contradicts the route, so nothing is sent to it.
        if delivery.kind == Self.cosmosMemoDeliveryKind, !inboundAddress.isEmpty {
            throw USwapMultiSwapProvider.SwapError.invalidTransactionData
        }

        let network: ThorChainKit.Network = input.tokenIn.blockchainType == .mayaChain ? .mayaMainnet : .mainnet
        // A settlement-native input (RUNE, CACAO, secured) has no vault to pay into and takes a
        // MsgDeposit; anything with an inbound address is a transfer.
        let kind: ThorChainExecutable.Kind
        if !inboundAddress.isEmpty {
            kind = try .send(recipient: ThorChainKit.Address(inboundAddress, network: network))
        } else {
            kind = try .deposit(asset: Self.asset(token: input.tokenIn, network: network))
        }

        let adapter = adapterManager.adapter(for: input.tokenIn) as? ThorChainAdapter

        // The fee is always paid in the chain's native coin, on top of the amount swapped.
        var transactionError: Error?
        if let adapter {
            let insufficient = adapter.isNativeCoin
                ? input.amountIn + adapter.fee > adapter.availableBalance
                : input.amountIn > adapter.availableBalance || adapter.fee > adapter.runeAvailableBalance
            if insufficient {
                transactionError = ThorChainKit.SendError.insufficientBalance
            }
        }

        return ThorChainSwapFinalQuote(
            amountIn: input.amountIn,
            expectedAmountOut: input.response.expectedBuyAmount,
            recipient: input.recipient,
            slippage: input.slippage,
            estimatedTime: input.response.estimatedTime,
            kind: kind,
            memo: memo,
            fee: adapter?.fee,
            transactionError: transactionError,
            toAddress: input.destinationAddress
        )
    }

    // The sold token's asset notation: the settlement coin for the native token, otherwise the
    // asset its bank denom names (the inverse of USwapAssetRepository's notation -> denom mapping).
    // The kit builds the MsgDeposit coin from the token's denom; the asset only labels it.
    private static func asset(token: Token, network: ThorChainKit.Network) throws -> ThorChainKit.Asset {
        switch token.type {
        case .native:
            return network.chain.nativeAsset
        case let .thorChainAsset(denom):
            return try network.chain.asset(for: denom)
        default:
            throw USwapMultiSwapProvider.SwapError.unsupportedTokenIn
        }
    }
}
