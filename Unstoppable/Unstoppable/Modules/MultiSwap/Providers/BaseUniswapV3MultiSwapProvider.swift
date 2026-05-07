import Alamofire
import EvmKit
import Foundation
import MarketKit
import UniswapKit

class BaseUniswapV3MultiSwapProvider: BaseUniswapMultiSwapProvider {
    private let networkManager = Core.shared.networkManager
    private let kit: UniswapKit.KitV3

    init(kit: UniswapKit.KitV3) {
        self.kit = kit

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

    override func track(swap: Swap) async throws -> Swap {
        let blockchainType = swap.tokenIn.blockchainType

        var parameters: Parameters = [
            "provider": swap.providerId,
            "toAddress": swap.toAddress,
        ]

        func set(_ dict: inout Parameters, _ key: String, _ value: Any?) {
            guard let value else { return }
            dict[key] = value
        }

        set(&parameters, "hash", swap.txHash)
        set(&parameters, "chainId", USwapMultiSwapProvider.blockchainTypeMap.first(where: { $0.value == blockchainType })?.key)
        set(&parameters, "fromAsset", evmAsset(token: swap.tokenIn))
        set(&parameters, "toAsset", evmAsset(token: swap.tokenOut))
        set(&parameters, "providerSwapId", swap.providerSwapId)

        return try await USwapMultiSwapProvider.track(swap: swap, parameters: parameters, networkManager: networkManager, isEvm: true)
    }

    private func evmAsset(token: MarketKit.Token) -> String? {
        switch token.type {
        case .native: return "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        case let .eip20(address): return address
        default: return nil
        }
    }
}
