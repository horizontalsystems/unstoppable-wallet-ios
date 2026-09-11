import BigInt
import EvmKit
import MarketKit
import OneInchKit
import UniswapKit

/// Swap amounts decoded from the transaction being replaced, without a new provider quote.
struct EvmResendSwapData {
    let tokenIn: MarketKit.Token
    let tokenOut: MarketKit.Token
    let amountIn: SwapDecoration.Amount
    let amountOut: SwapDecoration.Amount
    let recipient: EvmKit.Address?
    let kind: Kind

    init?(decoration: TransactionDecoration?, baseToken: MarketKit.Token, token: (EvmKit.Address) -> MarketKit.Token?) {
        switch decoration {
        case let swap as SwapDecoration:
            guard let tokenIn = Self.token(swap.tokenIn, baseToken: baseToken, resolve: token),
                  let tokenOut = Self.token(swap.tokenOut, baseToken: baseToken, resolve: token)
            else { return nil }

            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            amountIn = swap.amountIn
            amountOut = swap.amountOut
            recipient = swap.recipient
            kind = .uniswap
        case let swap as OneInchSwapDecoration:
            guard let tokenIn = Self.token(swap.tokenIn, baseToken: baseToken, resolve: token),
                  let tokenOut = Self.token(swap.tokenOut, baseToken: baseToken, resolve: token)
            else { return nil }

            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            amountIn = .exact(value: swap.amountIn)
            amountOut = Self.amount(swap.amountOut)
            recipient = swap.recipient
            kind = .oneInch
        case let swap as OneInchUnoswapDecoration:
            guard let output = swap.tokenOut,
                  let tokenIn = Self.token(swap.tokenIn, baseToken: baseToken, resolve: token),
                  let tokenOut = Self.token(output, baseToken: baseToken, resolve: token)
            else { return nil }

            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            amountIn = .exact(value: swap.amountIn)
            amountOut = Self.amount(swap.amountOut)
            recipient = nil
            kind = .oneInch
        default:
            return nil
        }
    }

    private static func token(_ token: SwapDecoration.Token, baseToken: MarketKit.Token, resolve: (EvmKit.Address) -> MarketKit.Token?) -> MarketKit.Token? {
        switch token {
        case .evmCoin: return baseToken
        case let .eip20Coin(address, _): return resolve(address)
        }
    }

    private static func token(_ token: OneInchDecoration.Token, baseToken: MarketKit.Token, resolve: (EvmKit.Address) -> MarketKit.Token?) -> MarketKit.Token? {
        switch token {
        case .evmCoin: return baseToken
        case let .eip20Coin(address, _): return resolve(address)
        }
    }

    private static func amount(_ amount: OneInchDecoration.Amount) -> SwapDecoration.Amount {
        switch amount {
        case let .exact(value): return .exact(value: value)
        case let .extremum(value): return .extremum(value: value)
        }
    }

    enum Kind {
        case uniswap
        case oneInch
    }
}
