import EvmKit
import Foundation
import MarketKit
import UniswapKit

class BaseUniswapV2MultiSwapProvider: BaseUniswapMultiSwapProvider {
    private let kit: UniswapKit.Kit

    init(kit: UniswapKit.Kit, storage: MultiSwapSettingStorage) {
        self.kit = kit

        super.init(storage: storage)
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

    override func trade(rpcSource: RpcSource, chain: Chain, tokenIn: UniswapKit.Token, tokenOut: UniswapKit.Token, amountIn: Decimal, tradeOptions: TradeOptions) async throws -> Quote.Trade {
        let swapData = try await kit.swapData(rpcSource: rpcSource, chain: chain, tokenIn: tokenIn, tokenOut: tokenOut)
        let tradeData = try kit.bestTradeExactIn(swapData: swapData, amountIn: amountIn, options: tradeOptions)
        return .v2(tradeData: tradeData)
    }

    override func transactionData(receiveAddress: EvmKit.Address, chain: Chain, trade: Quote.Trade, tradeOptions _: TradeOptions) throws -> TransactionData {
        guard case let .v2(tradeData) = trade else {
            throw SwapError.invalidTrade
        }

        return try kit.transactionData(receiveAddress: receiveAddress, chain: chain, tradeData: tradeData)
    }
}
