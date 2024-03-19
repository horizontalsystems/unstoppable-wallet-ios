import EvmKit
import Foundation
import MarketKit
import UniswapKit

class BaseUniswapV3MultiSwapProvider: BaseUniswapMultiSwapProvider {
    private let kit: UniswapKit.KitV3

    init(kit: UniswapKit.KitV3, storage: MultiSwapSettingStorage) {
        self.kit = kit

        super.init(storage: storage)
    }

    override func spenderAddress(chain: Chain) throws -> EvmKit.Address {
        kit.routerAddress(chain: chain)
    }

    override func kitToken(chain: Chain, token: MarketKit.Token) throws -> UniswapKit.Token {
        switch token.type {
        case .native: return try kit.etherToken(chain: chain)
        case let .eip20(address): return try kit.token(contractAddress: EvmKit.Address(hex: address), decimals: token.decimals)
        default: throw SwapError.invalidToken
        }
    }

    override func trade(rpcSource: RpcSource, chain: Chain, tokenIn: UniswapKit.Token, tokenOut: UniswapKit.Token, amountIn: Decimal, tradeOptions: TradeOptions) async throws -> Quote.Trade {
        let bestTrade = try await kit.bestTradeExactIn(rpcSource: rpcSource, chain: chain, tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, options: tradeOptions)
        return .v3(bestTrade: bestTrade)
    }

    override func transactionData(receiveAddress: EvmKit.Address, chain: Chain, trade: Quote.Trade, tradeOptions: TradeOptions) throws -> TransactionData {
        guard case let .v3(bestTrade) = trade else {
            throw SwapError.invalidTrade
        }

        return try kit.transactionData(receiveAddress: receiveAddress, chain: chain, bestTrade: bestTrade, tradeOptions: tradeOptions)
    }
}
