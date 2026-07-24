import EvmKit
import Foundation
import MarketKit
import UniswapKit

public class BaseUniswapV3MultiSwapProvider: BaseUniswapMultiSwapProvider {
    private let kit: UniswapKit.KitV3
    private let tracker: USwapTracker

    public init(kit: UniswapKit.KitV3, tracker: USwapTracker) {
        self.kit = kit
        self.tracker = tracker

        super.init()
    }

    override func spenderAddress(chain: Chain) throws -> EvmKit.Address {
        try kit.routerAddress(chain: chain)
    }

    override func kitToken(chain: Chain, token: MarketKit.Token) throws -> UniswapKit.Token {
        switch token.type {
        case .native: return try kit.etherToken(chain: chain)
        case let .eip20(address): return try kit.token(contractAddress: EvmKit.Address(hex: address), decimals: token.decimals)
        default: throw SwapError.invalidToken
        }
    }

    override func trade(rpcSource: RpcSource, chain: Chain, tokenIn: UniswapKit.Token, tokenOut: UniswapKit.Token, amountIn: Decimal, tradeOptions: TradeOptions) async throws -> UniswapMultiSwapQuote.Trade {
        let bestTrade = try await kit.bestTradeExactIn(rpcSource: rpcSource, chain: chain, tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, options: tradeOptions)
        return .v3(bestTrade: bestTrade)
    }

    override func transactionData(receiveAddress: EvmKit.Address, chain: Chain, trade: UniswapMultiSwapQuote.Trade, tradeOptions: TradeOptions) throws -> TransactionData {
        guard case let .v3(bestTrade) = trade else {
            throw SwapError.invalidTrade
        }

        return try kit.transactionData(receiveAddress: receiveAddress, chain: chain, bestTrade: bestTrade, tradeOptions: tradeOptions)
    }

    override public func track(swap: Swap) async throws -> Swap {
        let blockchainType = swap.tokenIn.blockchainType

        return try await tracker.track(
            swap: swap,
            request: .evm(
                providerId: swap.providerId,
                toAddress: swap.toAddress,
                transactionHash: swap.txHash,
                chainId: USwapAssetRepository.blockchainTypeMap.first(where: { $0.value == blockchainType })?.key,
                fromAsset: evmAsset(token: swap.tokenIn),
                toAsset: evmAsset(token: swap.tokenOut),
                providerSwapId: swap.providerSwapId
            )
        )
    }

    private func evmAsset(token: MarketKit.Token) -> String? {
        switch token.type {
        case .native: return "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        case let .eip20(address): return address
        default: return nil
        }
    }
}
