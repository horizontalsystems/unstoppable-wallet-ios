import Combine
import Foundation
import MarketKit

public protocol USwapSubProvider {
    var info: USwapProviderInfo { get }
    var syncPublisher: AnyPublisher<Void, Never>? { get }

    func slippageSupported(tokenIn: Token, tokenOut: Token) -> Bool
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func rate(input: USwapRateInput) async throws -> USwapRateResult
    /// No side effects: the route for the confirmation screen (carries a `previewToken`)
    func preview(input: USwapPreviewInput) async throws -> USwapPreviewResult
    /// Creates the order for a previewed route. Throws `USwapMultiSwapApi.CommitError` on failure.
    func commit(previewToken: String) async throws -> USwapMultiSwapApi.CommitResponse
    // Reports the broadcast hash of a committed order (best-effort, after a successful broadcast)
    func reportSigned(uuid: String, inboundTxHash: String) async throws
    func splitRate(tokenIn: Token, tokenOut: Token, amountIn: Decimal, percents: [Int]) async throws -> USwapMultiSwapApi.SplitRoute
    // No side effects, as `preview(input:)`
    func splitPreview(input: USwapSplitPreviewInput) async throws -> USwapSplitPreviewResult
    // Creates the split order. Throws `USwapMultiSwapApi.CommitError` on failure.
    func splitCommit(previewToken: String) async throws -> USwapMultiSwapApi.SplitCommitResponse
    func reportSplitSigned(splitUuid: String, inboundTxHash: String) async throws
    func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool?
    func track(swap: Swap) async throws -> Swap
}

/// Split (Private) swap support is opt-in: sub-providers that can't quote a split inherit these.
public extension USwapSubProvider {
    func splitRate(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, percents _: [Int]) async throws -> USwapMultiSwapApi.SplitRoute {
        throw SplitSwapError.notSupported
    }

    func splitPreview(input _: USwapSplitPreviewInput) async throws -> USwapSplitPreviewResult {
        throw SplitSwapError.notSupported
    }

    func splitCommit(previewToken _: String) async throws -> USwapMultiSwapApi.SplitCommitResponse {
        throw SplitSwapError.notSupported
    }

    func reportSplitSigned(splitUuid _: String, inboundTxHash _: String) async throws {
        throw SplitSwapError.notSupported
    }
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

public struct USwapSplitPreviewInput {
    public let tokenIn: Token
    public let tokenOut: Token
    public let amountIn: Decimal
    public let recipients: [SplitRecipient]
    public let slippage: Decimal
    public let transactionSettings: TransactionSettings?
}

public struct USwapSplitPreviewResult {
    public let route: USwapMultiSwapApi.SplitRoute
    public let refundAddress: String?
}
