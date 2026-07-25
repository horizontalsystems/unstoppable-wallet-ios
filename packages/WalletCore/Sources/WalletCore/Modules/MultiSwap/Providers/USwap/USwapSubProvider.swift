import Combine
import Foundation
import MarketKit

protocol USwapSubProvider {
    var info: USwapProviderInfo { get }
    var syncPublisher: AnyPublisher<Void, Never>? { get }

    func slippageSupported(tokenIn: Token, tokenOut: Token) -> Bool
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func mevProtectionAllowed(tokenIn: Token, tokenOut: Token) -> Bool
    func rate(input: USwapRateInput) async throws -> USwapRateResult
    func commit(input: USwapCommitInput) async throws -> USwapCommitResult
    func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool?
    func track(swap: Swap) async throws -> Swap
}

struct USwapRateInput {
    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    let slippage: Decimal
}

struct USwapRateResult {
    protocol Replay {}

    protocol Carrying: AnyObject {
        var replay: (any Replay)? { get }
    }

    let response: USwapMultiSwapApi.RateQuote
    let replay: (any Replay)?

    init(response: USwapMultiSwapApi.RateQuote, replay: (any Replay)? = nil) {
        self.response = response
        self.replay = replay
    }
}

struct USwapCommitInput {
    let multiSwapQuote: MultiSwapQuote
    let tokenIn: Token
    let tokenOut: Token
    let amountIn: Decimal
    let slippage: Decimal
    let recipient: String?
    let transactionSettings: TransactionSettings?
}

struct USwapCommitResult {
    let response: USwapMultiSwapApi.SwapResponse
    let refundAddress: String?
    let destinationAddress: String
}
