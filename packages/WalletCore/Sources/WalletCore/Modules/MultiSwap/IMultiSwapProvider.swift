import Combine
import Foundation
import MarketKit
import SwiftUI

public protocol IMultiSwapProvider {
    var id: String { get }
    var name: String { get }
    var type: SwapProviderType { get }
    var requireTerms: Bool { get }
    var preciseEstimateTime: Bool { get }
    var icon: String { get }
    var syncPublisher: AnyPublisher<Void, Never>? { get }
    func slippageSupported(tokenIn: Token, tokenOut: Token) -> Bool
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote
    func confirmationQuote(multiSwapQuote: MultiSwapQuote, tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> SwapFinalQuote
    func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool?
    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView
    func track(swap: Swap) async throws -> Swap
    // Creates the order for a previewed quote when the user confirms. Resolves to a `SwapCommitment`:
    // the quote whose executable is broadcast (the same instance, or a rebuilt one when a transfer
    // provider learns the deposit address only here) and the order id. `finalQuote` is the instance
    // the confirmation screen is displaying, so nothing visible on it is written to; only the
    // provider-private `providerContext` may be cleared, so a consumed preview is never committed twice.
    func commit(finalQuote: SwapFinalQuote) async throws -> SwapCommitment
    // Reports the broadcast hash to the backend after a successful submit. Best-effort.
    func reportInboundTxHash(providerSwapId: String, txHash: String) async throws
}

public extension IMultiSwapProvider {
    var requireTerms: Bool {
        false
    }

    var preciseEstimateTime: Bool {
        true
    }

    var syncPublisher: AnyPublisher<Void, Never>? {
        nil
    }

    func slippageSupported(tokenIn _: Token, tokenOut _: Token) -> Bool {
        true
    }

    func validateTrustedProvider(tokenIn _: Token, amountIn _: Decimal) async -> Bool? {
        if let result = Core.instance?.localStorage.debuggingAmlCheckResult {
            return result == .dirty ? false : nil
        }
        return true
    }

    func commit(finalQuote: SwapFinalQuote) async throws -> SwapCommitment {
        SwapCommitment(quote: finalQuote, providerSwapId: finalQuote.providerSwapId)
    }

    func reportInboundTxHash(providerSwapId _: String, txHash _: String) async throws {}
}

// What a confirmed order resolves to: the quote whose executable is broadcast and the order id the
// record tracks by. Carried beside the quote so the previewed instance is never written to. The sell
// amount is always the previewed one (the amount the user confirmed), so it is not repeated here.
public struct SwapCommitment {
    public let quote: SwapFinalQuote
    public let providerSwapId: String?

    public init(quote: SwapFinalQuote, providerSwapId: String?) {
        self.quote = quote
        self.providerSwapId = providerSwapId
    }
}

public enum SwapProviderType: String, CaseIterable, Identifiable {
    case excellent
    case good
    case fair

    public var title: String {
        "swap.quotes.providers.risk_levels.\(rawValue)".localized
    }

    public var icon: String {
        switch self {
        case .excellent: return "star_filled"
        case .good: return "shield_check_filled"
        case .fair: return "thumbsup"
        }
    }

    public var colorStyle: ColorStyle {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        }
    }

    public var id: String {
        rawValue
    }
}
