import Combine
import Foundation
import MarketKit
import SwiftUI

public protocol IMultiSwapProvider {
    var id: String { get }
    var name: String { get }
    var type: SwapProviderType { get }
    var requireTerms: Bool { get }
    var icon: String { get }
    // True when the provider swaps on a privacy-preserving rail. Mirrors the server's
    // `privacy.confidential` on /v2/providers, so the "confidential only" filter never needs a
    // hardcoded list of provider ids.
    var isConfidential: Bool { get }
    var syncPublisher: AnyPublisher<Void, Never>? { get }
    func slippageSupported(tokenIn: Token, tokenOut: Token) -> Bool
    func supports(tokenIn: Token, tokenOut: Token) -> Bool
    func mevProtectionAllowed(tokenIn: Token, tokenOut: Token) -> Bool
    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote
    func confirmationQuote(multiSwapQuote: MultiSwapQuote, tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> SwapFinalQuote
    func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool?
    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView
    func track(swap: Swap) async throws -> Swap
}

extension IMultiSwapProvider {
    var requireTerms: Bool {
        false
    }

    // Every native in-app provider (1inch, Uniswap, THORChain, …) is a public swap; only the
    // USwap sub-providers that say otherwise opt in. `public` so conformers OUTSIDE this package
    // (e.g. the Stable app's AA provider) inherit the default instead of failing to compile.
    public var isConfidential: Bool {
        false
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

    func mevProtectionAllowed(tokenIn _: Token, tokenOut _: Token) -> Bool {
        false
    }
}

public enum SwapProviderType: String, CaseIterable, Identifiable {
    case excellent
    case good
    case fair

    public var title: String {
        rawValue.capitalized(with: .autoupdatingCurrent)
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
