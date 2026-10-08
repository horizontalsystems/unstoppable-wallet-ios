import Combine
import Foundation
import MarketKit

public protocol USwapSubProvider {
    var info: USwapProviderInfo { get }
    var syncPublisher: AnyPublisher<Void, Never>? { get }

    func slippageSupported(tokenIn: Token, tokenOut: Token) -> Bool
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func rate(input: USwapRateInput) async throws -> USwapRateResult
    // No side effects: the route for the confirmation screen (carries a `previewToken`)
    func preview(input: USwapPreviewInput) async throws -> USwapPreviewResult
    // Creates the order for a previewed route. Throws `USwapMultiSwapApi.CommitError` on failure.
    func commit(previewToken: String) async throws -> USwapMultiSwapApi.CommitResponse
    // Reports the broadcast hash of a committed order (best-effort, after a successful broadcast)
    func reportSigned(uuid: String, inboundTxHash: String) async throws
    func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool?
    func track(swap: Swap) async throws -> Swap
}

public struct USwapRateInput {
    public let tokenIn: Token
    public let tokenOut: Token
    public let amountIn: Decimal
    public let slippage: Decimal

    public init(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.slippage = slippage
    }
}

public struct USwapRateResult {
    public protocol Replay {}

    protocol Carrying: AnyObject {
        var replay: (any Replay)? { get }
    }

    public let response: USwapMultiSwapApi.RateQuote
    public let replay: (any Replay)?

    public init(response: USwapMultiSwapApi.RateQuote, replay: (any Replay)? = nil) {
        self.response = response
        self.replay = replay
    }
}

public struct USwapPreviewInput {
    public let multiSwapQuote: MultiSwapQuote
    public let tokenIn: Token
    public let tokenOut: Token
    public let amountIn: Decimal
    public let slippage: Decimal
    public let recipient: String?
    public let transactionSettings: TransactionSettings?

    public init(
        multiSwapQuote: MultiSwapQuote,
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        slippage: Decimal,
        recipient: String?,
        transactionSettings: TransactionSettings?
    ) {
        self.multiSwapQuote = multiSwapQuote
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.slippage = slippage
        self.recipient = recipient
        self.transactionSettings = transactionSettings
    }
}

public struct USwapPreviewResult {
    public let response: USwapMultiSwapApi.SwapResponse
    public let refundAddress: String?
    public let destinationAddress: String

    public init(response: USwapMultiSwapApi.SwapResponse, refundAddress: String?, destinationAddress: String) {
        self.response = response
        self.refundAddress = refundAddress
        self.destinationAddress = destinationAddress
    }
}
